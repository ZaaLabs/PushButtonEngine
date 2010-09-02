/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.screens
{
    
    import com.pblabs.engine.core.*;
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.engine.time.IAnimatedObject;
    import com.pblabs.engine.time.IProcessManager;
    import com.pblabs.engine.time.ITickedObject;
    import com.pblabs.engine.time.ProcessManager;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.*;
    import flash.filters.BlurFilter;
    import flash.filters.ColorMatrixFilter;
    import flash.geom.Point;
    import flash.utils.*;
    
    /**
     * A simple system for managing a game's UI.
     * 
     * <p>The ScreenManager lets you have a set of named screens. The
     * goto(), push(), and pop() methods let you move from screen
     * to screen in an easy to follow way. A screen is just a DisplayObject
     * which implements IScreen; the included classes are all AS, but if you
     * entirely use Flex, you can use .mxml, too.</p>
     * 
     * <p>To use, first register screen instances by calling registerScreen.
     * Each screen has a unique name. That is what you pass to goto() and 
     * push().</p>
     * 
     * <p>The ScreenManager maintains a stack of screens. Only the topmost 
     * screen is added to the display list, for efficiency. If you want a
     * dialog or another element which only partially covers the screen,
     * you will probably want to use a different system.</p>
     * 
     * <p>The ScreenManager also allows you to filter what DisplayObjects get
     * events, in order to limit what the user can interact with, for modal/
     * drag-drop interactions.</p>
     */
    public class ScreenManager implements IAnimatedObject, ITickedObject, IPBManager
    {
//        [Inject]
//        public var context:IPBContext;
        
        [Inject]
        public var game:PBGame;
        
        [Inject]
        public var processManager:IProcessManager;
        
        /**
         * If this array is empty, it has no effect.
         * 
         * If it contains any DisplayObjects, then all mouse and keyboard inputs
         * are filtered to only those DOs and their children (if any). Roll out
         * events are not filtered to allow buttons to properly de-focus/highlight.
         * 
         * ScreenManager owns this to allow modals and other state changes to
         * interact properly with the event filtering.
         */
        public var allowedControls:Array = [];
        
        public function ScreenManager()
        {
            _screenContainer.name = "ScreenContainer";
            _screenProxy.name = "ScreenProxy";
            _dialogContainer.name = "DialogContainer";
            _modalContainer.name = "ModalContainer";
        }
        
        /**
         * Initialize the ScreenManager.
         */
        public function startup():void
        {
            processManager.addTickedObject(this);
            processManager.addAnimatedObject(this);
            
            // See if we can safely add Sprites to the mainClass, 
            // if so it is our screenParent, else, use stage.
            var mainClassAcceptsSprites:Boolean = false;
            try
            {
                var s:Sprite = new Sprite();
                game.mainClass.addChild(s);
                game.mainClass.removeChild(s);
                mainClassAcceptsSprites = true;
            }
            catch(e:Error)
            {
                mainClassAcceptsSprites = false;
                Logger.warn(this, "startup", "Detected Flex application, adding screens to stage not document class.");
            }
            
            screenParent = mainClassAcceptsSprites ? game.mainClass : game.mainStage;
            
            // Register the allowedControls event hooks.
            for each(var e:String in eventsToEat)
            {
                game.mainStage.addEventListener(e, eatEvent, true);
            }
            
        }
        
        public function shutdown():void
        {
            // Unhook the allowedControls listeners.
            for each(var e:String in eventsToEat)
            {
                game.mainStage.removeEventListener(e, eatEvent, true);
            }			
        }
        
        /**
         * Associate a named screen with the ScreenManager.
         */
        public function registerScreen(name:String, instance:IScreen):void
        {
            screenDictionary[name] = instance;
            
            // Debug aid.
            var ido:DisplayObject = instance as DisplayObject;
            if(ido && ido.name.indexOf("instance") != -1)
                ido.name = "Screen_" + name;
            
            game.injectInto(instance);
        }
        
        /**
         * Get a screen by name. 
         * @param name Name of the string to get.
         * @return Requested screen.
         */
        public function get(name:String):IScreen
        {
            return screenDictionary[name];
        }
        
        /**
         * Go to a named screen.
         */
        private function set currentScreen(value:String):void
        {
            if(_currentScreen)
            {
                _currentScreen.onHide();
                
                _currentScreen = null;
            }
            
            if(value)
            {
                _currentScreen = screenDictionary[value];
                if(!_currentScreen)
                    throw new Error("No such screen '" + value + "'");
                
                _currentScreen.onShow();
            }
        }
        
        /**
         * @returns The screen currently being displayed, if any.
         */
        public function getCurrentScreen():IScreen
        {
            return _currentScreen;
        }
        
        /**
         * This is where the screens are added and removed. Normally it is
         * set to Global.mainClass, but you may want to override it for
         * special cases.
         */
        public function get screenParent():DisplayObjectContainer
        {
            return _screenParent;
        }
        
        /**
         * @private
         */
        public function set screenParent(value:DisplayObjectContainer):void
        {
            if(_screenParent)
            {
                // Remove the containers if we had an old parent.
                _screenParent.removeChild(_screenContainer);
                _screenParent.removeChild(_dialogContainer);
                _screenParent.removeChild(_modalContainer);
            }
            
            _screenParent = value;
            
            if(_screenParent)
            {
                // Add the containers again.
                _screenParent.addChild(_screenContainer);
                _screenParent.addChild(_dialogContainer);
                _screenParent.addChild(_modalContainer);                
            }
        }
        
        /**
         * Return true if a screen of given name exists. 
         * @param screenName Name of screen.
         * @return True if screen exists.
         * 
         */
        public function hasScreen(screenName:String):Boolean
        {
            return get(screenName) != null;
        }
        
        /**
         * Switch to the specified screen, altering the top of the stack.
         * @param screenName Name of the screen to switch to.
         */
        public function goto(screenName:String):void
        {
            pop();
            push(screenName);
        }
        
        /**
         * Switch to the specified screen, saving the current screen in the 
         * stack so you can pop() and return to it later.  
         * @param screenName Name of the screen to switch to.
         */
        public function push(screenName:String):void
        {
            screenStack.push(screenName);
            currentScreen = screenName;
            
            _screenContainer.addChild(get(screenName) as DisplayObject);
        }
        
        /**
         * Pop the top of the stack and change to the new top element. Useful
         * for returning to the previous screen when it push()ed to the
         * current one.
         */ 
        public function pop():void
        {
            if(screenStack.length == 0)
            {
                Logger.warn(this, "pop", "Trying to pop empty ScreenManager.");
                return;
            }
            
            var oldScreen:DisplayObject = get(screenStack.pop()) as DisplayObject;
            currentScreen = screenStack[screenStack.length - 1];
            
            if(oldScreen && oldScreen.parent)
                oldScreen.parent.removeChild(oldScreen);
        }
        
        /**
         * The active screen receives frame updates.
         */  
        public function onFrame(elapsed:Number):void
        {
            if(_currentScreen)
                _currentScreen.onFrame(elapsed);
        }
        
        /**
         * The active screen is ticked.
         */  
        public function onTick(tickRate:Number):void
        {
            if(_currentScreen)
                _currentScreen.onTick(tickRate);
            
            if(_currentModal)
                centerCurrentModal();
        }
        
        /**
         * @private
         */  
        public function onInterpolateTick(i:Number):void
        {            
        }
        
        /**
         * Stick a displayobject so that it lives on top of the rest of the world (but behind modals).
         */
        public function showDialog(dialog:DisplayObject):void
        {
            _dialogContainer.addChild(dialog);
        }
        
        public function hideDialog(dialog:DisplayObject):void
        {
            if(dialog.parent == _dialogContainer)
                dialog.parent.removeChild(dialog);
        }
        
        /**
         * Stick a modal dialog into the queue. It will get shown eventually.
         */
        public function showModalDialog(dialog:BaseModalDialog, ...ignore):void
        {
            game.injectInto(dialog);
            
            // Put it in the queue, and update if needed.
            _modalQueue.push(dialog);
            updateModalState();
        }
        
        public function hideModalDialog(dialog:BaseModalDialog):void
        {
            // Is it on screen currently?
            if(_currentModal == dialog)
                hideCurrentModal();
            
            // Remove it from the queue...
            var qIdx:int = _modalQueue.indexOf(dialog);
            if(qIdx == -1)
                Logger.warn(this, "hideModalDialog", "Could not find modal in modal queue!");
            else
                _modalQueue.splice(qIdx, 1);
            
            // And update the modal state.
            updateModalState();
        }
        
        protected function updateModalState():void
        {
            // Look for highest priority modal.
            var highestP:Number = -1;
            var highestIdx:int = -1;
            for(var i:int=0; i<_modalQueue.length; i++)
            {
                const m:BaseModalDialog = _modalQueue[i] as BaseModalDialog;
                
                // Remove non-relevant modals.
                if(m.isRelevant == false)
                {
                    _modalQueue.splice(i, 1);
                    i--;
                    continue;
                }
                
                // Find max priority.
                if(m.priority >= highestP)
                {
                    highestP = m.priority;
                    highestIdx = i;
                }
            }
            
            // Now we know the topmost dialog if any.
            var highestModal:BaseModalDialog;
            if(highestIdx >= 0)
                highestModal = _modalQueue[highestIdx];
            else
                highestModal = null;
            
            // Display it.
            if(highestModal)
            {
                // Make sure the scrim is up.
                if(_currentModal == null)
                {
                    // Need to grab scrim.
                    addScrim();
                }
                
                // Something to show - already visible?
                if(_currentModal == highestModal && _modalContainer.getChildIndex(highestModal) != -1)
                {
                    // Already visible, we are good.
                }
                else
                {
                    // Maybe hide an old modal?
                    if(_currentModal != highestModal)
                        hideCurrentModal();
                    
                    // Show the new modal.
                    _currentModal = highestModal;
                    _modalContainer.addChild(_currentModal);
                }
                
                // Make sure it's centered.
                centerCurrentModal();
            }
            else
            {
                // Nothing to show - maybe hide an old modal?
                hideCurrentModal();
                
                // Make sure the scrim is not up.
                removeScrim();
            }
        }
        
        public function addScrim():void
        {
            if(_screenProxy.parent != null)
                return;
            
            // Temporarily go to high quality.
            //            PBE.pushStageQuality(StageQuality.HIGH);
            
            Logger.print(this, "Snapshotting...");
            
            
            // Make sure the screen proxy is ready to go.
            if(!_screenProxy)
            {
                _screenProxy = new Bitmap();
                _screenProxy.name = "ScreenProxy";
            }
            
            if(_screenProxy.bitmapData == null 
                || _screenProxy.bitmapData.width != game.mainStage.stageWidth 
                || _screenProxy.bitmapData.height != game.mainStage.stageHeight)
            {
                _screenProxy.bitmapData = new BitmapData(game.mainStage.stageWidth, game.mainStage.stageHeight, false, game.mainStage.opaqueBackground as int);
            }
            else
            {
                // Make sure to clear it so we don't get accumulation.
                _screenProxy.bitmapData.fillRect(_screenProxy.bitmapData.rect, game.mainStage.opaqueBackground as int);
            }
            
            // Ok, draw the screen to it.
            var bd:BitmapData = _screenProxy.bitmapData;
            bd.draw(_currentScreen as DisplayObject);
            
            // Blur and greyscale it.
            bd.applyFilter(bd, bd.rect, new Point(0,0), new BlurFilter());
            bd.applyFilter(bd, bd.rect, new Point(0,0), new ColorMatrixFilter([0.65,0.1,0.1,0,0,0.1,0.65,0.1,0,0,0.1,0.1,0.65,0,0,0,0,0,1,0]));
            
            // Overlay the proxy.
            _screenParent.addChildAt(_screenProxy, _screenParent.getChildIndex(_screenContainer) + 1);
            _screenContainer.visible = false;
        }
        
        public function removeScrim():void
        {
            if(_screenProxy.parent == null)
                return;
            
            // Switch the screen back in.
            _screenProxy.parent.removeChild(_screenProxy as DisplayObject);
            _screenContainer.visible = true;
            
            // Go back to low quality.
            //            PBE.popStageQuality();
        }        
        
        /**
         * If there is a current model, hide it.
         */
        protected function hideCurrentModal():void
        {
            if(_currentModal == null)
                return;
            
            _currentModal.parent.removeChild(_currentModal);
            _currentModal = null;
        }
        
        protected function centerCurrentModal():void
        {
            if(_currentModal == null)
                return;
            
            // Let it position itself.
            _currentModal.positionModal();
            
            //Logger.print(this, "Centered modal, x=" + _currentModal.x + ", y=" + _currentModal.y);
        }
        
        protected function eatEvent(e:Event):void
        {
            // Do nothing if no allowed controls.
            if(allowedControls.length == 0)
                return;
            
            // Walk up the hierarchy and see if this or parents are in allowedSet.
            var walk:DisplayObject = e.target as DisplayObject;
            var devour:Boolean = true;
            while(walk && walk != walk.stage)
            {
                // Did we find anything valid?
                if(allowedControls.indexOf(walk) != -1)
                {
                    devour = false;
                    break;
                }
                
                // Keep on walking...
                walk = walk.parent;
            }
            
            // Ok, if it's not allowed, eat it.
            if(devour)
            {
                //Logger.print(this, "Intercepting " + e.type + " to " + e.target + ".");
                e.stopImmediatePropagation();
                e.stopPropagation();
                e.preventDefault();
            }
        }
        
        /**
         * Events which the allowedControls functionality filters. 
         */
        protected var eventsToEat:Array = [
            MouseEvent.CLICK,
            MouseEvent.DOUBLE_CLICK, 
            MouseEvent.MOUSE_DOWN, 
            MouseEvent.MOUSE_MOVE, 
            MouseEvent.MOUSE_OUT, 
            MouseEvent.MOUSE_OVER, 
            MouseEvent.MOUSE_UP, 
            MouseEvent.MOUSE_WHEEL, 
            //MouseEvent.ROLL_OUT, -- Allowed so UI doesn't get stuck with highlights.
            MouseEvent.ROLL_OVER,
            KeyboardEvent.KEY_DOWN,
            KeyboardEvent.KEY_UP,
        ];
        
        protected var _screenContainer:Sprite = new Sprite();
        protected var _screenProxy:Bitmap = new Bitmap();
        protected var _dialogContainer:Sprite = new Sprite();
        protected var _modalContainer:Sprite = new Sprite();
        
        protected var _currentModal:BaseModalDialog;
        protected var _modalQueue:Array = [];
        
        /**
         * This is where the screens are added and removed. Normally it is
         * set to Global.mainClass, but you may want to override it for
         * special cases.
         */ 
        protected var _screenParent:DisplayObjectContainer = null;
        
        protected var _currentScreen:IScreen = null;
        protected var screenStack:Array = [null];
        protected var screenDictionary:Dictionary = new Dictionary();
    }
}