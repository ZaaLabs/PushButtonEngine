package
{
    import com.pblabs.rendering2D.ui.PBButton;
    import com.pblabs.rendering2D.ui.PBLabel;
    import com.pblabs.screens.*;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.text.TextFormatAlign;

    /**
     * Screen displayed when the game is over.
     */
    public class GameOverScreen extends BaseScreen
    {
        public var statusLabel:PBLabel = new PBLabel();
        public var restartButton:PBButton = new PBButton();
        
        [Inject]
        public var eventBus:EventDispatcher;
        
        public function GameOverScreen()
        {
            addChild(statusLabel);
            statusLabel.fontAlign = TextFormatAlign.CENTER;
            statusLabel.caption = "Game Complete!";
            statusLabel.extents = new Rectangle(320-150, 240-100, 300, 100);
            statusLabel.fontSize = 32;
            statusLabel.refresh();
            
            addChild(restartButton);
            restartButton.label = "Restart";
            restartButton.extents = new Rectangle(387, 308, 160, 40);
            restartButton.fontSize = 32;
            restartButton.refresh();
            
            restartButton.addEventListener(MouseEvent.CLICK, function(e:*):void
            {
                eventBus.dispatchEvent(new Event(RollyBallGame.RESET_GAME_EVENT));
            });
        }
    }
}