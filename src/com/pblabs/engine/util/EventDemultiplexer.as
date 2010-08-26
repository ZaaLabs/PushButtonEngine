package com.pblabs.engine.util
{
    import com.pblabs.engine.PBUtil;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    
    /**
     * Utility class to coalesce multiple event sources into a single
     * callback.
     */
    public class EventDemultiplexer
    {                
        /**
         * If true, we don't do a callback until every source has fired at least
         * once. Thereafter, any source firing will result in a calback.
         */
        public var requireAllAtLeastOnce:Boolean = true;
        
        /**
         * Function to call when our conditions are met.
         */
        public var outputCallback:Function;
        
        protected var numberOfSourcesLeftToFire:int = 0;
        protected var sources:Array = [];
        
        /**
         * Add an event source to the demux. 
         * @param source The dispatcher to listen to.
         * @param eventType The event to listen for.
         * 
         */
        public function addEventSource(source:IEventDispatcher, eventType:String):void
        {
            // Set up the entry.
            var ede:EventDemultiplexerEntry = new EventDemultiplexerEntry();
            ede.firedOnce = false;
            ede.source = source;
            ede.type = eventType;
            ede.callback = PBUtil.closurizeAppend(eventHandler, ede);

            // Update set of sources.
            numberOfSourcesLeftToFire++;
            sources.push(ede);
            
            // Register the listener.
            source.addEventListener(eventType, ede.callback);
        }
        
        /**
         * Remove a previously registered source. Call with identical parameters as
         * you called addEventSource.
         */
        public function removeEventSource(source:IEventDispatcher, eventType:String):void
        {
            // Look for and remove the item.
            for(var i:int=0; i<sources.length; i++)
            {
                var curEde:EventDemultiplexerEntry = sources[i];
                
                if(curEde.source != source)
                    continue;
                
                if(curEde.source != eventType)
                    continue;
                
                // Match! Remove the entry and the listener.
                source.removeEventListener(eventType, curEde.callback);
                numberOfSourcesLeftToFire--;
                sources.splice(i, 1);
                return;
            }
            
            throw new Error("No such source found.");
        }
        
        /**
         * Remove every source we have been considering.
         */
        public function removeAllEventSources():void
        {
            // Remove all registered event listeners.
            for(var i:int=0; i<sources.length; i++)
            {
                var curEde:EventDemultiplexerEntry = sources[i];
                curEde.source.removeEventListener(curEde.type, curEde.callback);
            }
            
            numberOfSourcesLeftToFire = 0;
            sources.length = 0;
        }    

        protected function eventHandler(e:Event, ede:EventDemultiplexerEntry):void
        {
            // Update state of source.
            if(ede.firedOnce == false)
            {
                ede.firedOnce = true;
                numberOfSourcesLeftToFire--;
            }

            // May be time for a callback.
            if(numberOfSourcesLeftToFire == 0 || !requireAllAtLeastOnce)
                outputCallback();
        }
    }
}