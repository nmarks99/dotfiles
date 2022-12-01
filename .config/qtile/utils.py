import os

def gen_unique_filename(default_name,extension, directory="./"):
    '''
    Generates a string "default_name.extension" if a file 
    of that name does not already exist in the directory "directory". If a file of that 
    name already exists, the generated string will be "default_name_1.extension". If that 
    already exists, the string will be "default_name_2.extension" and so on.
    '''
    
    # Create a data folder if it doesn't exist
    if directory != "./":
        if not os.path.isdir(directory):
            os.system("".join(["mkdir ",directory]))
     
    contents = os.listdir(directory)
    nums = []
    f = False
    for name in contents:
        print(name)
        if default_name in name:
            f = True
            for ch in name:
                if ch.isdigit():
                    nums.append(int(ch))
            nums.sort()

    if not f:
        outfile = "".join([directory,default_name,extension])
    else:
        if len(nums) >= 1:
            n = nums[-1]
            outfile = "".join([directory,default_name,"_{}".format(n+1),extension])
        else:
            outfile = "".join([directory,default_name,"_1",extension])

    return outfile


def brint(text, color=None, clear=False):
    '''
    "brint" = "better print"
    
    Works like the normal python print function
    but with optional parameters "color" to set
    the font color using ANSI escape codes, and 
    "clear" which clears the console window 
    prior to printing if set to True.

    Color options:
    "RED"
    "GREEN"
    "YELLOW"
    "BLUE"
    "MAGENTA"
    "CYAN"
    "WHITE"
    "BOLD_RED"
    "BOLD_GREEN"
    "BOLD_YELLOW"
    "BOLD_BLUE"
    "BOLD_MAGENTA"
    "BOLD_CYAN"
    "BOLD_WHITE"
    '''

    escapes_dict = { 
        "RESET" : "\x1B[0m",
        "RED" : "\x1B[0;31m",
        "GREEN" : "\x1B[0;32m",
        "YELLLOW" : "\x1B[0;33m",
        "BLUE" : "\x1B[0;34m",
        "MAGENTA" : "\x1B[0;35m",
        "CYAN" : "\x1B[0;36m",
        "WHITE" : "\x1B[0;37m",
        "BOLD_RED" : "\x1B[1;31m",
        "BOLD_GREEN" : "\x1B[1;32m",
        "BOLD_YELLOW" : "\x1B[1;33m",
        "BOLD_BLUE" : "\x1B[1;34m",
        "BOLD_MAGENTA" : "\x1B[1;35m",
        "BOLD_CYAN" : "\x1B[1;36m",
        "BOLD_WHITE" : "\x1B[1;37m"
    }
    
    assert(isinstance(text,str)), "text must be a string"

    if color is not None:
        assert(isinstance(color,str)),"color must be a string"
        esc_code = escapes_dict[color.upper()]
        reset = escapes_dict["RESET"]
        out_str = "".join([esc_code,text,reset])
    else:
        out_str = text
    
    # Clear the screen first if requested
    if clear:
        os.system("clear || cls")

    print(out_str)

