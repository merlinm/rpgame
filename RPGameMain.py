import streamlit as st
from sqlalchemy.engine import URL, create_engine
from sqlalchemy.orm import Session
from sqlalchemy.sql import text
#import sys
import scene_builder

def main():
    st.set_page_config(layout="wide")

    scene = st.empty()

    connection_url = URL.create(
        "postgresql+psycopg2",
        username="student",
        password="rpstudent",
        host="rpgame.org",
        database="student"
        )

    engine = create_engine(connection_url)

    dbcon = Session(engine)

    scene_builder.InitialBuild()
    scene_builder.SceneChanger(scene, dbcon, st.session_state.scene)

if __name__ == "__main__":
    main()