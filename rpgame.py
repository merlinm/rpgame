# https://docs.sqlalchemy.org/en/20/core/engines.html
from sqlalchemy.engine import URL, create_engine
# from sqlalchemy.sql import table, column, select
from sqlalchemy import text

def main():

    connection_url = URL.create(
        "postgresql+psycopg2",
        username="student",
        password="rpstudent",
        host="rpgame.mooo.com",
        database="student"
        )

    engine = create_engine(connection_url)

    with engine.connect() as connection:
        result = connection.execute(text("select * from command;"))
        for each in result:
            print(each)
    
    print("Success!")


if __name__ == "__main__":
    main()


#HOMEWORK
# Get the login screen to work
# Take the asciimatics form and use the details to be sent to the database not to a temp databse
# Class that will have the user id and the game id to be able to use througout the game

# Have to develop each screen
# Database connection library
# Ascii framework library > asciimatics
# Try to get a screen working 
# Idea to have a box where the SQL database will return the data already formatted like it does in the terminal /console