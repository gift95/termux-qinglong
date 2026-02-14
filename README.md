# termux-qinglong
在termux 中安装青龙面板
第一步 先安装Alpine镜像
```bash
cd $HOME && curl -LO https://raw.githubusercontent.com/Hax4us/TermuxAlpine/master/TermuxAlpine.sh && bash TermuxAlpine.sh
```
第二步 进入alpine 并安装青龙面板
```bash
startalpine
```
```bash
apk update && apk add curl bash  sudo
```
```bash
curl -LO https://raw.githubusercontent.com/gift95/termux-qinglong/refs/heads/main/installAlpineQL.sh && bash installAlpineQL.sh
```
第三步 进入青龙面板
浏览器访问 127.0.0.1:5700/
