package com.pblabs.engine.core
{
    public interface IPBContextRegistration extends IPBContext
    {
        function register(object:IPBObject):void;
        function unregister(object:IPBObject):void;        
    }
}