## Description
This script will replace default Gothic 2 Online event handling mechanism, providing you more posibilities and control over it.

## Features
- OOP based event control
- Manual and automatic context control
- Ability to change event priority 'on the fly'
- More convenient way to remove event handlers

## Downsides
- Some parts of your current code may be incompatible, so you'll need to fix it a bit (see more in Usage section)
- Function **isEventCancelled** currently is not working

## How to connect
- Place all the files into your server directory
- Import **event_handler.xml** in your config file

## Usage

```C++
instance addEventHandler(string eventName, function func, int priority = 9999)
```
Differences compared to the original: now returns an instance, that you can manipulate even further, or store it for later use.

```C++
instance removeEventHandler(instance event)
```
Differences compared to the original: in addition to basic variation of **removeEventHandler**, now you can pass only instance that you've got from **addEventHandler**

```C++
instance event.context(reference context [, bool autoDelete = false])
```
Differences compared to the original: new method which you can call from instance that **addEventHandler** will return. Will set this event handler's context to the one you've provided. If you pass an additional argument autoDelete 
equals to **true**, then the event handler will be removed once provided context will be **null**. 

```C++
instance event.priority(int priority)
```
Differences compared to the original: new method which you can call from instance that **addEventHandler** will return. Will set this event handler's priority to the one you've provided.

```C++
void eventValue(int eventValue)
```
Differences compared to the original: function is no longer working, if you want to change event value - put **your value** into return statement, like ```return 50;```.

```C++
void cancelEvent()
```
Differences compared to the original: function is no longer working, if you want to cancel the event - put **false** into return statement, like ```return false```.

## Examples
```C++
function onInit()
{
  print("Hello!");
}

addEventHandler("onInit", onInit).priority(5);
```

```C++
local evtHandler = -1;

function onCommand(cmd, params)
{
  if(cmd == "say")
    print(params);
  if (cmd == "delete")
    removeEventHandler(evtHandler);
}

evtHandler = addEventHandler("onCommand", onCommand);
```

```C++
local data = {name = "AURUMVORAX", hp = 50};

function onCommand(cmd, params)
{
  if(cmd == "get_hp")
    print(name + "'s health: " + hp);  // prints "AURUMVORAX's health: 50"
  if (cmd == "purge")
    data = null;                       // this command will delete the context, and so this event handler
}

addEventHandler("onCommand", onCommand).context(data, true).priority(100);
```

```C++
local a_players = [];

class CPlayer
{
  id = -1;
  money = 0;

  constructor(pid)
  {
    id = pid;

    addEventHandler("onPlayerDead", evtDead).context(this, true);    // event handler will be deleted when the object will be deleted
  }

  function evtDead(pid, kid)
  {
    if (pid == id)
      money = 0;
    else if (kid == id)
      money += 500;
  }
}

addEventHandler("onPlayerJoin", function(pid)
{
  a_players.push(CPlayer(pid));
});

addEventHandler("onPlayerDisconnect", function(pid, reason)
{
  for (local i = 0; i < a_players.len(); i++)
  {
    if (a_players[i].id == pid)
      a_players.remove(i);
  }
});
```
