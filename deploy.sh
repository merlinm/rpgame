#!/bin/bash

git pull
pkill streamlit
echo sleep to allow for application to stop
sleep 3
echo starting streamlit
nohup streamlit run RPGameMain.py &
