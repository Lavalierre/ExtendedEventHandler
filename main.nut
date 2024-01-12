
_ExtendedEventHandler               <- {}
_ExtendedEventHandler.EVTMANAGER    <- null;

local __addEventHandler             = addEventHandler;
local __removeEventHander           = removeEventHandler;

class _ExtendedEventHandler.CEvent
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
        _ExtendedEventHandler.EVTMANAGER.refreshEvents();
        return this;
    }

    function _getPriority() { return i_priority; }
    function _getName()     { return s_evtName; }
    function _getFunc()     { return r_function; }
    function _getContext()  { return r_env; }
    function _getDelete()   { return b_autoDelete; }
}

class _ExtendedEventHandler.CEventManager
{
    a_events        = [];
    a_callerEvents  = [];

    constructor() {};

    function registerEvent(_name, _ref, _priority)
    {
        local newEvent = _ExtendedEventHandler.CEvent(_name, _ref, _priority);
        a_events.push(newEvent);

        registerCallerEvent(_name);
        refreshEvents();

        return newEvent;
    }

    function registerCallerEvent(_name)
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

    function unregisterEvent(_name, _ref)
    {
        local evt = getEventsByName(_name, _ref);
        if (evt.len() != 0)
        {
            for (local i = evt.len() - 1; i != -1; i--)
                a_events.remove(evt[i]);
            
            return true;
        }

        return false;
    }

    function deleteEvent(evt)
    {
        local idx = a_events.find(evt);
        if (idx != null)
        {
            a_events.remove(idx);
            return true;
        }

        return false;
    }

    function getEventsByName(_name, _func)
    {
        local returnArr = [];

        for (local i = 0; i < a_events.len(); i++)
        {
            if (a_events[i]._getFunc() == _func && a_events[i]._getName() == _name)
                returnArr.append(i);
        }

        return returnArr;
    }

    function refreshEvents()
    {
        a_events.sort(@(a,b) a._getPriority() <=> b._getPriority());
    }

    function isCallerEventExists(_name)
    {
        for (local i = 0; i < a_callerEvents.len(); i++)
        {
            if (a_callerEvents[i].name == _name)
                return true;
        }

        return false;
    }

    function callerEvent(...)
    {
        local evt = _ExtendedEventHandler.EVTMANAGER.a_events;
        for (local i = 0; i < evt.len(); i++)
        {
            if (evt[i]._getName() == name)
            {
                if (evt[i]._getContext() == null && evt[i]._getDelete())
                {
                    _ExtendedEventHandler.EVTMANAGER.deleteEvent(evt[i]);
                    continue;
                }

                vargv.insert(0, evt[i].r_env);
                local result = evt[i].r_function.acall(vargv);

                if(result == false)
                    cancelEvent();
                else if (typeof result == "integer")
                    eventValue(result);
            }
        }
    }
}

// *** DEFAULT G2O FUNCTIONS *** //

function addEventHandler(name, ref, priority = 9999)
{
    if (_ExtendedEventHandler.EVTMANAGER == null)   _ExtendedEventHandler.EVTMANAGER = _ExtendedEventHandler.CEventManager();

    return _ExtendedEventHandler.EVTMANAGER.registerEvent(name, ref, priority);
}

function removeEventHandler(...)
{
    if (typeof vargv[0] == "string" && vargv.len() == 2)
        return _ExtendedEventHandler.EVTMANAGER.unregisterEvent(vargv[0], vargv[1]);
    else if (typeof vargv[0] == "instance" && vargv.len() == 1)
        return _ExtendedEventHandler.EVTMANAGER.deleteEvent(vargv[0]);

    return false;
}

// *** //