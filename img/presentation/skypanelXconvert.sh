#!/bin/sh
ffmpeg -t 3 -i skypanelXdemo.mp4 -vf "fps=23,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 skypanelXdemo.gif