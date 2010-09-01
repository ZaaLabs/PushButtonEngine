package
{
    import com.pblabs.engine.serialization.LevelContext;
    import com.pblabs.engine.time.IAnimatedObject;
    import com.pblabs.engine.time.ITickedObject;
    import com.pblabs.engine.time.ProcessManager;
    
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    
    public class RollyBallGameLevelContext extends LevelContext implements IAnimatedObject, ITickedObject
    {
        public var display:Sprite = new Sprite();
        
        public var sceneView:SceneView = new SceneView();
        public var lblTime:PBLabel = new PBLabel();
        public var lblScore:PBLabel = new PBLabel();
        
        // State of this level.
        public var startTime:int = 0;
        public var levelDuration:int = 45000;
        public var currentTime:int = levelDuration;
        public var currentScore:int = 0;
        
        [Inject]
        public var processManager:ProcessManager;
        
        public function RollyBallGameLevelContext(name:String, levelUrl:String, group:String)
        {
            super(name, levelUrl, group);
            
            // Set up the UI.
            
            // Set up the scene view to be full screen.
            sceneView.name = "MainView";
            sceneView.width = 640;
            sceneView.height = 480;
            display.addChild(sceneView);
            
            // Label to display the time remaining.
            addChild(lblTime);
            lblTime.extents = new Rectangle(0, 0, 150, 30);
            lblTime.fontColor = 0xFFFF00;
            lblTime.fontSize = 24;
            display.lblTime.refresh();
            
            // Score indicator (also a label).
            addChild(lblScore);
            lblScore.extents = new Rectangle(640 - 150, 0, 150, 30);
            lblScore.fontColor = 0xFFFF00;
            lblScore.fontSize = 24;
            lblScore.fontAlign = TextFormatAlign.RIGHT;
            display.lblScore.refresh();
        }
        
        public override function startup():void
        {
            super.startup();
            
            mainStage.addChild(display);
            
            processManager.addAnimatedObject(this);
            processManager.addTickedObject(this);
        }
        
        public override function shutdown():void
        {
            processManager.removeTickedObject(this);
            processManager.removeAnimatedObject(this);

            mainStage.removeChild(display);
            
            super.shutdown();
        }
        
        /**
         * Called every frame; used to update time remaining and score. Only display
         * aspects of the game are updated here. You will notice that currentTime
         * is updated; that is so it is always super-smooth, but the gameplay
         * logic happens in onTick.
         */
        public function onFrame(dt:Number):void
        {
            // Update the 
            currentTime = levelDuration - (processManager.virtualTime - startTimer);
            
            // Update time.
            if(RollyBallGame.currentTime >= 0)
                lblTime.caption = "Time: " + (currentTime/1000).toFixed(2);
            else
                lblTime.caption = "Time: 0.00";
            lblTime.refresh();
            
            // Update score.
            lblScore.caption = "Score: " + currentScore;
            lblScore.refresh();            
        }

        
        /**
         * Gameplay logic happens here; in this game, the only thing is to check
         * if the user is out of time.
         */
        public function onTick(delta:Number) : void
        {
            // Deal with timing logic.
            if(currentTime <= 0 && processManager.isTicking)
            {
                // Stop playing!
                processManager.stop();
                
                // Kick off the scoreboard.
                var sb:Scoreboard = new Scoreboard();
                display.addChild(sb);
                sb.StartReport(currentScore);
            }
        }        

        
        public function resetTimerAndScore():void
        {
            startTimer = processManager.virtualTime;
            currentScore = 0;
            currentTime = 0.0;            
        }
        
        public function resetLevel():void
        {
            // Reset the level.
            var curLevel:int = LevelManager.instance.currentLevel;
            
            // Reset the coins.
            var cs:PBSet = PBE.lookup("CoinSet") as PBSet;
            if(cs)
                cs.clear();
            
            // Hack to properly reset level data - level 0 is always loaded
            // and has special logic in the manager, so we have to do this 
            // hack for now -- BJG
            LevelManager.instance.loadLevel(curLevel == 1 ? 2 : 1);
            LevelManager.instance.loadLevel(curLevel);
            
            // Reset the timer and score.
            resetTimerAndScore();
        }
        
        public function restartGame():void
        {
            // Reset the coins.
            var cs:PBSet = PBE.lookup("CoinSet") as PBSet;
            if(cs)
                cs.clear();
            
            // Reset the level.
            LevelManager.instance.loadLevel(1);
            
            // Reset the timer and score.
            resetTimerAndScore();
        }
        
        public function nextLevel():void
        {
            // Reset the coins.
            var cs:PBSet = PBE.lookup("CoinSet") as PBSet;
            if(cs)
                cs.clear();
            
            // Advance level as appropriate.
            if(LevelManager.instance.currentLevel < 2)
            {
                LevelManager.instance.loadNextLevel();               
                
                // Reset the timer.
                resetTimerAndScore();
                
                ScreenManager.instance.goto("game");
            }
            else
            {
                ScreenManager.instance.goto("gameOver");
            }
        }    
        
    }
}