import re

# Test
# username = 'karls.mundaray@realpage.com'
    
class IsValid:
    #Checks a username is an email address
    @classmethod
    def user_id(cls, username) -> bool:
        # Complex for email username
        # if re.search(r"^\w+\.?\w*@\w+\.\w{2,3}$", username.strip()):
        # Easy username
        if re.search(r"^\w+$", username.strip()):
            return True
        else:
            return False

# Test
# result = IsValid.user_id(username)
# print(result)

    @classmethod
    def password(cls, password) -> bool:
        # Easy Password
        if re.search(r"^\w+$", password.strip()):
            return True
        else:
            return False
        

#   . any character except a newline
#   * 0 or more repetitions
#   + 1 or more repetitions
#   ? 0 or 1 repetitions
#   {m} m repetitions 
#   {m,n} m-n repetitions range
#   ^ match the start of the string
#   $ matches the end of the string or just before the newline
#   [] set of characters
#   [^] complementing the set. Cannot match any of the characters.
#   \w word character… as well as numbers and the underscore
#   \W not a word character
#   \d decimal digit
#   \D not a decimal digit
#   \s whitespace characters 
#   \S not a whitespace character
#   A|B either A or B
#   (…) a group
#   (?:...) non-capturing version

