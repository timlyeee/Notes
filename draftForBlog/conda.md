# Conda的安装和不同环境的运行

## 安装

> Package, dependency and environment management for any language—Python, R, Ruby, Lua, Scala, Java, JavaScript, C/ C++, FORTRAN, and more.

conda的功能很全，可以切换任意版本的语言环境，但是安装完整版的conda实在耗费空间，所以推荐安装Miniconda，并且装在非系统盘。用法相同但是可以自定义环境。比如对于我来说，更多时候是用来控制不同的python环境，在2.7和3.6之间切换python版本。

搜索Miniconda并且安装推荐的包。这时候如果想在指定的命令行里使用conda的命令需要添加环境变量。但是conda提供了一个更方便的命令行启动方法，在Anaconda prompt里面输入conda init $SHELL_NAME 即可激活相对应shell的conda命令。

比如windows上用git bash环境运行conda环境管理

```sh
#in Anaconda Prompt
conda init bash
```

然后打开git bash会有以下信息

```bash
(base)
Administrator MINGW64 ~
$ 

```

我们再使用git bash创建一个python 2.7的环境并切换至该环境。

```bash
conda create -n py27 python=2.7
conda activate py27
```

## Windows

conda init实际上会创建不同的shell脚本来提供给不同命令行使用，尤其是在Windows上有多个命令行工具的情况下。conda init powershell和conda init cmd.exe都很重要，可以通过conda init -h查看详细。