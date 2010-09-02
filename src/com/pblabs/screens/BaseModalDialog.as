package com.pblabs.screens
{
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.core.IPBContext;
    
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;
    
    public class BaseModalDialog extends Sprite
    {

		protected var _dontReposition:Boolean = false;

        public static const MODAL_KILL:String = "modalKill";

        [Inject]
        public var context:IPBContext;
        
		[Inject]
		public var screenManager:ScreenManager;
		
        public function get isRelevant():Boolean
        {
            return true;
        }
        
        public function get priority():Number
        {
            return 1;
        }

        public function get modalWidth():Number
        {
            return width;
        }
        
        public function get modalHeight():Number
        {
            return height;
        }
        
        /**
         * Called to position us as desired (default is centered, change it however you like for custom modals). 
         */
        public function positionModal():void
        {
			if(this._dontReposition == true) return;
            x = ((context.mainStage.stageWidth - modalWidth) / 2);
            y = ((context.mainStage.stageHeight - modalHeight) / 2);
        }
        
        /**
         * Get rid of this modal, allowing any additional modals to be 
         * displayed.
         * 
         * If this modal is contained in another, it will automatically 
         * traverse up and kill it instead.
         * 
         * In addition, an event is fired for things that want to listen.
         */
        public function killModal():void
        {
            // Make sure we are the rootmost modal, as some jerks like to nest modals...
            var walk:DisplayObject = this;
            var topModal:BaseModalDialog = this;
            
            while(walk)
            {
                if(walk && walk is BaseModalDialog)
                    topModal = walk as BaseModalDialog;
                walk = walk.parent;
            }

            // Hide it, fire events for good times.
            screenManager.hideModalDialog(topModal);
            dispatchEvent(new Event(MODAL_KILL));
        }
    }
}