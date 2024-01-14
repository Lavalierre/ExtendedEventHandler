
local __addEventHandler             = addEventHandler;
local __removeEventHander           = removeEventHandler;

local a_events                      = [];
local a_callerEvents                = [];

local CEvent = class
{
    s_evtName       = null;
    i_priority      = null;
    r_function      = null;
    r_env           = null;
    b_autoDelete    = false;

    constructor(_evtName, _ref, _priority)
    {
        s_evtName   = _evtName;
        r_function  = _ref;
        i_priority  = _priority;
        r_env       = getroottable();
    }

    function context(_env, _delete = false)          
    { 
        r_env = _env.weakref(); 
        b_autoDelete = _delete; 
        return this;
    }

    function priority(_priority)                     
    { 
        i_priority = _priority; 
        a_events.sort(@(a,b) a._getPriority() <=> b._getPriority());
        return this;
    }

    function _getPriority() { return i_priority; }
    function _getName()     { return s_evtName; }
    function _getFunc()     { return r_function; }
    function _getContext()  { return r_env; }
    function _getDelete()   { return b_autoDelete; }
}

// *** //

local function isCallerEventExists(_name)
{
    for (local i = 0; i < a_callerEvents.len(); i++)
    {
        if (a_callerEvents[i].name == _name)
            return true;
    }

    return false;
}

local function getEvents(_name, _func)
{
    local returnArr = [];

    for (local i = 0; i < a_events.len(); i++)
    {
        if (a_events[i]._getFunc() == _func && a_events[i]._getName() == _name)
            returnArr.append(i);
    }

    return returnArr;
}

local function unregisterEvent(_name, _ref)
{
    local evt = getEvents(_name, _ref);
    if (evt.len() != 0)
    {
        for (local i = evt.len() - 1; i != -1; i--)
            a_events.remove(evt[i]);
            
        return true;
    }

    return false;
}

local function deleteEvent(evt)
{
    local idx = a_events.find(evt);
    if (idx != null)
    {
        a_events.remove(idx);
        return true;
    }

    return false;
}

local function getEventsByName(_name)
{
    local returnArr = [];

    for (local i = 0; i < a_events.len(); i++)
    {
        if (a_events[i]._getName() == _name)
            returnArr.append(a_events[i]);
    }

    return returnArr;
}

local function callerEvent(...)
{
    vargv.insert(0, null);

    local a_evt = getEventsByName(name);

    for (local i = 0; i < a_evt.len(); i++)
    {
        if (a_evt[i]._getContext() == null && a_evt[i]._getDelete())
        {
            deleteEvent(a_evt[i]);
            continue;
        }

        vargv[0] = a_evt[i]._getContext();
        local result = a_evt[i].r_function.acall(vargv);

            if(result == false)
                cancelEvent();
            else if (typeof result == "integer")
                eventValue(result);
    }
}

local function registerCallerEvent(_name)
{
    if (!isCallerEventExists(_name))
    {
        local newCallerEvent = {};
        newCallerEvent.name <- _name;
        newCallerEvent.func <- callerEvent.bindenv(newCallerEvent);
        a_callerEvents.append(newCallerEvent);
            
        __addEventHandler(_name, newCallerEvent.func);
    }
}

local function registerEvent(_name, _ref, _priority)
{
    local newEvent = CEvent(_name, _ref, _priority);
    a_events.push(newEvent);
    a_events.sort(@(a,b) a._getPriority() <=> b._getPriority());

    registerCallerEvent(_name);

    return newEvent;
}

// *** DEFAULT G2O FUNCTIONS *** //

function addEventHandler(name, ref, priority = 9999)
{
    return registerEvent(name, ref, priority);
}

function removeEventHandler(...)
{
    if (typeof vargv[0] == "string" && vargv.len() == 2)
        return unregisterEvent(vargv[0], vargv[1]);
    else if (typeof vargv[0] == "instance" && vargv.len() == 1)
        return deleteEvent(vargv[0]);

    return false;
}

// *** //