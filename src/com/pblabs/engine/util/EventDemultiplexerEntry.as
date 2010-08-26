package com.pblabs.engine.util
{
    import flash.events.IEventDispatcher;

    /**
     * Internally used by EventDemultiplexer.
     */
    internal final class EventDemultiplexerEntry
    {
        public var source:IEventDispatcher;
        public var type:String;
        public var firedOnce:Boolean;
        public var callback:Function;
    }
}