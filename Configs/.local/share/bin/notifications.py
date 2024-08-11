#!/usr/bin/python3

import subprocess
import json

import sys

def get_dunst_history():

    alt = 'none'
    tooltip_click = []
    tooltip_click.append("󰎟 Notifications")
    tooltip_click.append("󰳽 scroll-down:  history pop")
    tooltip_click.append("󰳽 click-left:  Enable & Disable DND")
    tooltip_click.append("󰳽 click-middle: 󰛌 clear history")
    tooltip_click.append("󰳽 click-right: 󱄊 close all")

    tooltip = []

    if count > 0:
        notifications = history['data'][0][:10]  # Get the first 10 notifications
        for notification in notifications:
            body = notification.get('body', {}).get('data', '')
            category = notification.get('category', {}).get('data', '')
            if category:
                alt = category + '-notification'
                tooltip.append(f" {body} ({category})\n")



            else:
                alt = 'notification'
                tooltip.append(f" {body}\n")


    isDND = subprocess.run(['dunstctl', 'get-pause-level'], stdout=subprocess.PIPE)
    isDND = isDND.stdout.decode('utf-8').strip()
    if isDND != '0':


    return formatted_history

def main():
    history = get_dunst_history()
    formatted_history = format_history(history)
    sys.stdout.write(json.dumps(formatted_history) + '\n')
    sys.stdout.flush()




if __name__ == "__main__":
    main()