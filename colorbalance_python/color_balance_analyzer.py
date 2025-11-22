import logging
from skimage import io, color, segmentation, util, transform
from sklearn.cluster import KMeans
import numpy as np
import matplotlib.pyplot as plt


logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)


class ColorBalanceAnalyzer:
    def __init__(self,
                 max_dim=1200,
                 gaussian_sigma=1.0,
                 n_segments=300,
                 compactness=20,
                 k_clusters=5,
                 merge_delta_e=15.0,
                 small_cluster_thresh=0.03):
        logging.info("Initializing ColorBalanceAnalyzer...")
        self.max_dim = max_dim
        self.gaussian_sigma = gaussian_sigma
        self.n_segments = n_segments
        self.compactness = compactness
        self.k_clusters = k_clusters
        self.merge_delta_e = merge_delta_e
        self.small_cluster_thresh = small_cluster_thresh

    # ----------------------------------------------------------------------
    # Helpers
    # ----------------------------------------------------------------------
    def _resize_keep_aspect(self, img):
        logging.info("Resizing image (keep aspect ratio)...")
        h, w = img.shape[:2]
        if max(h, w) <= self.max_dim:
            logging.info("Image smaller than max_dim; no resizing needed.")
            return img
        scale = self.max_dim / max(h, w)
        new_h = int(round(h * scale))
        new_w = int(round(w * scale))
        logging.info(f"Resized to {new_h} x {new_w}")
        img_resized = transform.resize(img, (new_h, new_w),
                                       anti_aliasing=True,
                                       preserve_range=True)
        return img_resized.astype(img.dtype)

    def _to_lab(self, img_rgb):
        return color.rgb2lab(util.img_as_float(img_rgb))

    def _to_rgb_uint8(self, img_float):
        img = np.clip(img_float, 0, 1)
        return (img * 255).astype(np.uint8)

    def _lab_to_hex(self, lab_color):
        lab = np.array(lab_color, dtype=float).reshape(1, 1, 3)
        rgb = color.lab2rgb(lab)
        rgb_u8 = self._to_rgb_uint8(rgb[0, 0])
        return '#{:02x}{:02x}{:02x}'.format(*rgb_u8)

    # ----------------------------------------------------------------------
    # Main entry point
    # ----------------------------------------------------------------------
    def analyze(self, image, output_filepath, show_plots=True):
        logging.info("Starting analysis... Loading image")

        if isinstance(image, str):
            img = io.imread(image)
            logging.info(f"Loaded image from path: {image}")
            if img.ndim == 2:
                logging.info("Image is grayscale → converting to RGB")
                img = color.gray2rgb(img)
        else:
            logging.info("Image provided as numpy array")
            img = image.copy()

        img = util.img_as_float(img)
        img = self._resize_keep_aspect(img)

        # Gaussian blur
        if self.gaussian_sigma and self.gaussian_sigma > 0:
            logging.info(f"Applying Gaussian blur (sigma={self.gaussian_sigma})")
            from skimage.filters import gaussian
            img = gaussian(img, sigma=self.gaussian_sigma,
                           channel_axis=2,
                           preserve_range=True)
            img = np.clip(img, 0, 1)

        logging.info("Converting image to LAB")
        lab = color.rgb2lab(img)

        # SLIC superpixels
        logging.info(f"Generating SLIC superpixels: n_segments={self.n_segments}")
        segments = segmentation.slic(
            img,
            n_segments=self.n_segments,
            compactness=self.compactness,
            start_label=0
        )
        n_segments_actual = segments.max() + 1
        logging.info(f"Actual segments generated: {n_segments_actual}")

        # Mean LAB per segment
        logging.info("Calculating mean LAB color per superpixel...")
        superpixel_colors = np.zeros((n_segments_actual, 3), dtype=float)
        superpixel_areas = np.zeros(n_segments_actual, dtype=int)

        for s in range(n_segments_actual):
            mask = (segments == s)
            superpixel_areas[s] = mask.sum()
            if superpixel_areas[s] > 0:
                superpixel_colors[s] = lab[mask].mean(axis=0)

        # Remove empty superpixels (very rare)
        valid = superpixel_areas > 0
        superpixel_colors = superpixel_colors[valid]
        superpixel_areas = superpixel_areas[valid]

        # KMeans clustering
        k = min(self.k_clusters, len(superpixel_colors))
        logging.info(f"Clustering colors using KMeans (k={k})")
        kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
        labels = kmeans.fit_predict(superpixel_colors)
        cluster_centers = kmeans.cluster_centers_

        # Cluster area computation
        logging.info("Computing area percentage per cluster...")
        cluster_areas = np.zeros(k, dtype=int)
        for i, label in enumerate(labels):
            cluster_areas[label] += superpixel_areas[i]

        total_area = cluster_areas.sum()
        cluster_percents = cluster_areas / total_area * 100.0

        # Build raw cluster list
        raw_clusters = []
        for i in range(k):
            raw_clusters.append({
                'label': int(i),
                'lab': cluster_centers[i].tolist(),
                'area': int(cluster_areas[i]),
                'percent': float(cluster_percents[i]),
                'hex': self._lab_to_hex(cluster_centers[i]),
            })

        # Merge clusters using ΔE2000
        logging.info("Merging perceptually similar clusters (ΔE2000)...")
        from skimage.color import deltaE_ciede2000
        merged_mask = [False] * len(raw_clusters)
        merged_clusters = []

        for i in range(len(raw_clusters)):
            if merged_mask[i]:
                continue

            base_lab = np.array(raw_clusters[i]['lab']).reshape(1, 3)
            total_a = raw_clusters[i]['area']
            weighted_lab = base_lab * raw_clusters[i]['area']

            merged_mask[i] = True

            for j in range(i + 1, len(raw_clusters)):
                if merged_mask[j]:
                    continue

                comp_lab = np.array(raw_clusters[j]['lab']).reshape(1, 3)
                distance = deltaE_ciede2000(base_lab, comp_lab)[0]

                if distance < self.merge_delta_e:
                    total_a += raw_clusters[j]['area']
                    weighted_lab += comp_lab * raw_clusters[j]['area']
                    merged_mask[j] = True

            avg_lab = (weighted_lab / total_a).reshape(3)
            merged_clusters.append({
                'lab': avg_lab.tolist(),
                'area': int(total_a),
                'percent': float(total_a / total_area * 100.0),
                'hex': self._lab_to_hex(avg_lab),
            })

        # Sort by area
        merged_clusters = sorted(merged_clusters,
                                 key=lambda c: c['area'],
                                 reverse=True)

        # Filter small clusters
        filtered_clusters = [
            c for c in merged_clusters
            if c['percent'] >= self.small_cluster_thresh * 100
        ]
        small_clusters = [
            c for c in merged_clusters
            if c['percent'] < self.small_cluster_thresh * 100
        ]

        logging.info("Evaluating 60-30-10 rule...")

        # 60-30-10 evaluation
        top3 = (filtered_clusters + small_clusters)[:3]
        while len(top3) < 3:
            top3.append({'percent': 0.0, 'hex': "#000000"})

        target = [60, 30, 10]
        tolerance = 8.0
        evaluation = []
        balanced = True

        for idx, t in enumerate(target):
            actual = top3[idx]['percent']
            diff = actual - t
            ok = abs(diff) <= tolerance
            if not ok:
                balanced = False

            evaluation.append({
                'position': idx + 1,
                'target_percent': t,
                'actual_percent': actual,
                'difference': diff,
                'within_tolerance': ok,
                'hex': top3[idx]['hex'],
            })

        result = {
            'raw_clusters': raw_clusters,
            'merged_clusters': merged_clusters,
            'filtered_clusters': filtered_clusters,
            'small_clusters': small_clusters,
            'total_area': int(total_area),
            '60_30_10_evaluation': {
                'top3': top3,
                'evaluation': evaluation,
                'balanced': balanced,
                'tolerance': tolerance,
            }
        }

        if show_plots:
            logging.info("Generating plots...")
            self._plot_results(img, segments, filtered_clusters, output_filepath)

        logging.info("Analysis complete.")
        return result

    # ----------------------------------------------------------------------
    # Plotting
    # ----------------------------------------------------------------------
    def _plot_results(self, img, segments, clusters, output_filepath="color_distribution.png"):
        logging.info(f"Saving plot to '{output_filepath}'...")

        fig = plt.figure(figsize=(12, 6))

        ax1 = fig.add_subplot(1, 3, 1)
        ax1.imshow(img)
        ax1.set_title("Input Image")
        ax1.axis("off")

        ax2 = fig.add_subplot(1, 3, 2)
        ax2.imshow(segmentation.mark_boundaries(img, segments))
        ax2.set_title("SLIC Superpixels")
        ax2.axis("off")

        ax3 = fig.add_subplot(1, 3, 3)
        n = len(clusters)
        swatch = np.ones((50, 50 * n, 3), dtype=np.uint8)
        for i, c in enumerate(clusters):
            rgb = np.array([
                int(c['hex'][1:3], 16),
                int(c['hex'][3:5], 16),
                int(c['hex'][5:7], 16)
            ])
            swatch[:, i * 50:(i + 1) * 50, :] = rgb

        ax3.imshow(swatch)
        ax3.set_title("Dominant Colors")
        ax3.axis("off")

        plt.tight_layout()

        # PNG Saving added here
        plt.savefig(output_filepath, dpi=300, bbox_inches="tight")

        # Still show if user wants interactive view
        plt.show()


if __name__ == "__main__":
    analyzer = ColorBalanceAnalyzer()
    input_image_path = "/Users/zhangxiaoxuan/Workplace/development/colorbalance/colorbalance_python/ocean.jpeg"
    output_plot_path = "/Users/zhangxiaoxuan/Workplace/development/colorbalance/colorbalance_python/ocean_distribution.png"
    result = analyzer.analyze(image=input_image_path, output_filepath=output_plot_path,show_plots=True)
    print(result)