from kittens.tui.handler import result_handler

def main(args):
    pass

@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    direction = args[1]
    tab = boss.active_tab
    if tab is None:
        return
    if tab.neighboring_group_id(direction):
        tab.neighboring_window(direction)
    elif boss.active_tab_manager is not None:
        boss.active_tab_manager.next_tab(1 if direction == "right" else -1)
