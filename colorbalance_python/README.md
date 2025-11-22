## Run pyenv
- Install pyenv
- Install python version through pyenv
```
pyenv install 3.12
```
- Check available python versions in pyenv
```
pyenv versions
```
- Activate python version locally

Navigate to project folder and run
```
pyenv local 3.12   
```
## Run venv
- Create virtual environment with pyenv
```
pyenv exec python3 -m venv .venv
```
- Activate venv
```    
source .venv/bin/activate
```