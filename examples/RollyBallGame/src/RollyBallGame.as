/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 * 
 * This file is property of PushButton Labs, LLC and NOT under the MIT license.
 ******************************************************************************/
package
{
    import com.pblabs.animation.*;
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.core.*;
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.engine.resource.ResourceManager;
    import com.pblabs.engine.serialization.LevelContext;
    import com.pblabs.engine.time.IProcessManager;
    import com.pblabs.engine.time.ProcessManager;
    import com.pblabs.rendering2D.*;
    import com.pblabs.rendering2D.spritesheet.*;
    import com.pblabs.rendering2D.ui.*;
    import com.pblabs.rollyGame.*;
    import com.pblabs.screens.*;
    
    import flash.display.*;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;
    
    [SWF(width="640", height="480", frameRate="30", backgroundColor="0x000000")]
    public class RollyBallGame extends Sprite
    {
        public static var game:PBGame = new PBGame();
        
        public static const NEXT_LEVEL_EVENT:String = "nextLevelEvent";
        public static const RESET_LEVEL_EVENT:String = "resetLevelEvent";
        public static const RESET_GAME_EVENT:String = "resetGameEvent";
        
        [Inject]
        public var resourceManager:ResourceManager;
        
        [Inject]
        public var processManager:IProcessManager;
        
        [Inject]
        public var eventBus:EventDispatcher;
        
        public var currentLevel:int = 1;
        
        public var levelMap:Object = 
            {
                1: "level1",
                2: "level2"
            };
        
        public function RollyBallGame()
        {
            // Make the game scale properly.
            stage.scaleMode = StageScaleMode.SHOW_ALL; 

            // Start the game!
            game.startup(this);
            game.addResourceBundle(new GameResources());
            
            // Register our types.
            game.registerType(com.pblabs.rendering2D.DisplayObjectScene);
            game.registerType(com.pblabs.rendering2D.SpriteSheetRenderer);
            game.registerType(com.pblabs.rendering2D.SimpleSpatialComponent);
            game.registerType(com.pblabs.rendering2D.BasicSpatialManager2D);
            game.registerType(com.pblabs.rendering2D.spritesheet.CellCountDivider);
            game.registerType(com.pblabs.rendering2D.spritesheet.SpriteSheetComponent);
            game.registerType(com.pblabs.rendering2D.ui.SceneView);
            game.registerType(com.pblabs.animation.AnimatorComponent);
            game.registerType(com.pblabs.rollyGame.NormalMap);
            game.registerType(com.pblabs.rollyGame.BallMover);
            game.registerType(com.pblabs.rollyGame.BallShadowRenderer);
            game.registerType(com.pblabs.rollyGame.BallSpriteRenderer);   

            // Enable this to ensure all resources are embedded.
            resourceManager.onEmbeddedFail = trace;
            resourceManager.onlyLoadEmbeddedResources = true;
            
            // Set up the levels.
            game.registerContext(new RollyBallGameLevelContext("level1", "../assets/Levels/level.pbelevel", "Level1"));
            game.registerContext(new RollyBallGameLevelContext("level2", "../assets/Levels/level.pbelevel", "Level2"));
            
            // Pause/resume based on focus.
            stage.addEventListener(Event.DEACTIVATE, function():void{ processManager.timeScale = 0; });
            stage.addEventListener(Event.ACTIVATE, function():void{ processManager.timeScale = 1; });
            
            // Listen for global game events.
            eventBus.addEventListener(RollyBallGame.NEXT_LEVEL_EVENT, onNextLevel);
            eventBus.addEventListener(RollyBallGame.RESET_LEVEL_EVENT, onResetLevel);
            eventBus.addEventListener(RollyBallGame.RESET_GAME_EVENT, onResetGame);
            
            // Go to first level.
            game.switchContext("level1");
        }
        
        protected function onNextLevel(e:Event):void
        {
            currentLevel++;
            
            // If the level exists, switch to it.
            if(levelMap.hasOwnProperty(currentLevel))
            {
                game.switchContext(levelMap[currentLevel]);
                return;
            }
            
            // Or to game over screen.
            addChild(game.currentContext.allocate(GameOverScreen));
        }

        protected function onResetGame(e:Event):void
        {
            currentLevel = 0;
            onNextLevel(null);
        }
        
        protected function onResetLevel(e:Event):void
        {
            // Switch away from and back to current level.
            game.switchContext(levelMap[currentLevel]);
        }
    }    
}