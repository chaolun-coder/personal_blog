@echo off
echo 正在清理旧文件...
call hexo clean

echo 正在生成静态文件...
call hexo generate

echo 正在部署到 GitHub Pages...
call hexo deploy

echo 部署完成！
pause