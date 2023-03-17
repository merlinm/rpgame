from asciimatics.widgets import Frame, ListBox, Layout, Divider, Text, \
    Button, TextBox, Widget
from asciimatics.scene import Scene
from asciimatics.screen import Screen
from asciimatics.exceptions import ResizeScreenError, NextScene, StopApplication
import sys
from sqlalchemy.engine import URL, create_engine
from sqlalchemy.orm import Session

#_________________________Database Engine________________________#
connection_url = URL.create(
    "postgresql+psycopg2",
    username="student",
    password="rpstudent",
    host="rpgame.mooo.com",
    database="student"
    )

engine = create_engine(connection_url)

rpgame_db = Session(engine)

#_______________________     ______________________#



#_________________________Login Page________________________#
class LoginView(Frame):
    def __init__(self, screen):
        super(LoginView, self).__init__(screen,
                                       screen.height * 2 // 3,
                                       screen.width * 2 // 3,
                                       hover_focus=True,
                                       can_scroll=False,
                                       title="RealPage Game")

        # Create the form for displaying the list of contacts.   # Have to switch to list of games
        self._list_view = ListBox(
            Widget.FILL_FRAME,
            name="login",
            add_scroll_bar = False,
            options = [("",0),
                       ("You must enter a Username and a Password.", 1), 
                       ("If no Username is found, a new one will be created.", 2)]
            )           

        layout = Layout([100], fill_frame=True)
        self.add_layout(layout)
        layout.add_widget(Text("Username:", "username"))    # Type Username to log in 
        layout.add_widget(Text("Password:", "password"))    # Type Password to log in
        layout.add_widget(self._list_view)
        layout.add_widget(Divider())
        layout2 = Layout([1, 1, 1, 1])
        self.add_layout(layout2)
        layout2.add_widget(Button("Log in", self._log_in), 0)
        layout2.add_widget(Button("Exit", self._exit), 3)
        self.fix()

    def _log_in(self):
        self.save()
        given_username = self.data['username'].lower()
        given_password = self.data['password']

        if given_username == "" or given_password == "":
            raise NextScene("Login")
        
        with rpgame_db as connection:
            connection.begin()
            result = connection.execute(
                f"Select LoginPlayer ('{given_username}','{given_password}');"
                )
            connection.commit()
            print(">>>>>>>", given_username, given_password)
            for row in result:
                print(row)
        raise NextScene("Main")

    @staticmethod
    def _exit():
        raise StopApplication("User pressed quit")


#_________________________Landing Page________________________#
class MainView(Frame):
    def __init__(self, screen):
        super(MainView, self).__init__(screen,
                                       screen.height * 2 // 3,
                                       screen.width * 2 // 3,
                                       on_load=self._reload_list,
                                       hover_focus=True,
                                       can_scroll=False,
                                       title="RealPage Game")

        # Create the form for displaying the list of contacts.   # Have to switch to list of games
        self._list_view = ListBox(
            Widget.FILL_FRAME,
            add_scroll_bar=True,
            on_change=self._on_pick,
            on_select=self._join,
            options = [([None], 1)])

        self._join_button = Button("Join", self._join)
        self._return_button = Button("Return", self._return)
        layout = Layout([100], fill_frame=True)
        self.add_layout(layout)
        layout.add_widget(self._list_view)
        layout.add_widget(Divider())
        layout2 = Layout([1, 1, 1, 1])
        self.add_layout(layout2)
        layout2.add_widget(Button("Create", self._create), 0)
        layout2.add_widget(self._join_button, 1)
        layout2.add_widget(self._return_button, 2)
        layout2.add_widget(Button("Exit", self._exit), 3)
        self.fix()
        self._on_pick()

    def _on_pick(self):
        self._join_button.disabled = self._list_view.value is None
        self._return_button.disabled = self._list_view.value is None

    def _reload_list(self, new_value=None):
        self._list_view.value = new_value

    def _create(self):
        raise NextScene("Edit Contact")

    def _join(self):
        self.save()
        raise NextScene("Edit Contact")

    def _return(self):
        self.save()
        self._reload_list()
        # raise NextScene("Return to Game")

    @staticmethod
    def _exit():
        raise StopApplication("User pressed quit")




#____________ Starts the Game _______________#
# Login view, game selection, game view
def game(screen, scene):
    scenes = [
        Scene([LoginView(screen)], -1, name="Login"),
        Scene([MainView(screen)], -1, name="Main"),
    ]

    screen.play(scenes, stop_on_resize=True, start_scene=scene, allow_int=True)



last_scene = None
while True:
    try:
        Screen.wrapper(game, catch_interrupt=True, arguments=[last_scene])
        sys.exit(0)
    except ResizeScreenError as e:
        last_scene = e.scene