package com.pblabs.core
{
    import com.greensock.OverwriteManager;
    import com.pblabs.debug.Console;
    import com.pblabs.debug.ConsoleCommandManager;
    import com.pblabs.debug.Logger;
    import com.pblabs.input.KeyboardManager;
    import com.pblabs.property.PropertyManager;
    import com.pblabs.time.TimeManager;
    
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.KeyboardEvent;
    
    /**
     * Sweet PushButton Engine demo application.
     * https://github.com/PushButtonLabs/PushButtonEngine
     * 
     * This demo application cycles amongst multiple demo "scenes" to show off
     * various parts of the engine's capabilities. Use < and > to change the 
     * demo. Press ~ (tilde) to bring up the console. Type help to learn about
     * more commands.
     * 
     * The demo scenes are all implemented in their own classes that live in 
     * the demo package. A great way to learn the engine is to read through
     * each demo, in order, and look at the demo app at the same time. 
     */
    [SWF(frameRate="32",wmode="direct")]
    public class PBGame extends Sprite
    {
        // Set up TweenMax plugins.
        OverwriteManager.init(OverwriteManager.AUTO);
        
        // Container for the active scene.
        public var rootGroup:PBGroup = new PBGroup();
        
        // List of level classes to extend
        public var levelList:Array = [];
        
        // Keep track of the current demo scene.
        public var currentLevelIndex:int = 0;
        public var currentLevel:PBGroup;
        
        /**
         * Initialize the demo and show the first scene.
         */
        public function PBGame()
        {
            // Set it so that the stage resizes properly.
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            
            // Set up the root group for the demo and register a few useful
            // managers. Managers are available via dependency injection to the
            // demo scenes and objects.
            rootGroup.initialize();
            rootGroup.name = "RootGroup";
            rootGroup.registerManager(Stage, stage);
            rootGroup.registerManager(PropertyManager, new PropertyManager());
            rootGroup.registerManager(ConsoleCommandManager, new ConsoleCommandManager());
            rootGroup.registerManager(TimeManager, new TimeManager());
            rootGroup.registerManager(KeyboardManager, new KeyboardManager());
            rootGroup.registerManager(Console, new Console());
            
            // Make sure first scene is loaded.
            updateScene();
        }
        
        /**
         * Called when the scene index is changed, to make sure the index is
         * valid, then to destroy the old demo scene, create the new demo scene,
         * and to update the UI.
         */
        protected function updateScene():void
        {
            // Make sure the current index is valid.
            if(currentLevelIndex < 0)
                currentLevelIndex = levelList.length - 1;
            else if(currentLevelIndex > levelList.length - 1)
                currentLevelIndex = 0;
            
            // Note our change in state.
            Logger.print(this, "Changing level to #" + currentLevelIndex + ": " + levelList[currentLevelIndex]);
            
            // Destroy old scene and instantiate new scene.
            if(currentLevel)
                currentLevel.destroy();
            
            if(levelList.length > 0)
            {
                currentLevel = new levelList[currentLevelIndex];
                currentLevel.owningGroup = rootGroup;
                currentLevel.initialize();
            }            
        }
        
        /**
         * Global key handler to switch scenes.
         */
        protected function onKeyUp(ke:KeyboardEvent):void
        {
            // Handle keys. We do this directly for simplicity.
            var keyAsString:String = String.fromCharCode(ke.charCode);
            var sceneChanged:Boolean = false;
            if(keyAsString == "<")
            {
                currentLevelIndex--;
                sceneChanged = true;
            }
            else if(keyAsString == ">")
            {
                currentLevelIndex++;
                sceneChanged = true;
            }
            
            if(sceneChanged)
            {
                updateScene();
            }
        }
    }
}