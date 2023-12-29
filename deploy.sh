git pull
pkill streamlit
#sorcery!
kill `ps -axf | grep "CALL Main" | grep -v grep | cut -d ' ' -f 2`
echo sleep to allow for application to stop
sleep 3
echo starting streamlit
nohup streamlit run RPGameMain.py &
nohup bash server.sh &
