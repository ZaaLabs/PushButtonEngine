/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 * 
 * This file is property of PushButton Labs, LLC and NOT under the MIT license.
 ******************************************************************************/
package com.pblabs.rollyGame
{
    import com.pblabs.animation.*;
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.core.*;
    import com.pblabs.engine.input.InputKey;
    import com.pblabs.engine.input.InputManager;
    import com.pblabs.engine.resource.*;
    import com.pblabs.engine.serialization.TemplateManager;
    import com.pblabs.rendering2D.*;
    import com.pblabs.sound.ISoundManager;
    import com.pblabs.sound.SoundManager;
    
    import flash.geom.*;
    
    /**
     * Class responsible for ball physics, input handling, and gameplay (ie, 
     * picking up gems).
     */
    public class BallMover extends SimpleSpatialComponent
    {
        [Inject]
        public var soundManager:ISoundManager;
        
        [Inject]
        public var inputManager:InputManager;
        
        [Inject]
        public var templateManager:TemplateManager;
        
        public var map:NormalMap;
        public var height:Number = 1.0;
        public var radius:Number = 16;
        public var trueRadius:Number = 16;
        public var ballScale:Point = new Point(1,1);
        public var moveForce:Number = 12;
        public var normalForce:Number = 35;
        public var dragCoefficient:Number = 0.95;
        public var pickupType:ObjectType = new ObjectType();
        public var pickupRadius:Number = 4;
        
        public var pickupSound:String;
        
        // Temporary objects to avoid allocations.
        protected static var tmpPoint:Point = new Point();
        protected static var tmpArray:Array = [];
        
        public override function onTick(tickRate:Number):void
        {
            // Sample input.
            _onLeft(inputManager.isKeyDown(InputKey.LEFT.keyCode) ? 1 : 0);
            _onRight(inputManager.isKeyDown(InputKey.RIGHT.keyCode) ? 1 : 0);
            _onUp(inputManager.isKeyDown(InputKey.UP.keyCode) ? 1 : 0);
            _onDown(inputManager.isKeyDown(InputKey.DOWN.keyCode) ? 1 : 0);
            
            // Sample the map for our current position.
            var n:Point = tmpPoint;
            n.x = 0; n.y = 0;
            if(map)
                height = map.getNormalAndHeight(position.x, position.y, n);
            
            // Scale the renderer.
            ballScale.x = (0.5 + height) * 32;
            ballScale.y = (0.5 + height) * 32;
            radius = (0.5 + height) * 16;
            
            // Apply velocity from slope.
            velocity.x += n.x * normalForce;
            velocity.y += n.y * normalForce;
            
            // Apply drag.
            velocity.x *= dragCoefficient;
            velocity.y *= dragCoefficient;
            
            // Apply movement forces.
            velocity.x += (_right - _left) * moveForce;
            velocity.y += (_down - _up) * moveForce;
            
            // Figure out if we need to bounce off the walls.
            if(position.x <= trueRadius && velocity.x < 0 || position.x >= 640 - trueRadius && velocity.x > 0)
                velocity.x = -velocity.x * 0.9;
            if(position.y <= trueRadius && velocity.y < 0 || position.y >= 480 - trueRadius && velocity.y > 0)
                velocity.y = -velocity.y * 0.9;
            
            // Update position.
            tmpPoint.x = position.x + velocity.x * tickRate; 
            tmpPoint.y = position.y + velocity.y * tickRate; 
            position = tmpPoint;
            
            // Look for stuff to pick up.
            var results:Array = tmpArray;
            results.length = 0;
            spatialManager.queryCircle(position, pickupRadius, pickupType, results);
            
            for(var i:int=0; i<results.length; i++)
            {
                // Nuke it!
                var so:IEntityComponent = results[i] as IEntityComponent;
                so.owner.destroy();
                
                // Grant score.
                (context as RollyBallGameLevelContext).currentScore++;
                if(pickupSound)
                    soundManager.play(pickupSound);
                
                // Spawn a new coin somewhere.
                templateManager.makeEntity(context, "Coin", 
                    {
                        "@Spatial.position": new Point(20 + Math.random() * 600, 20 + Math.random() * 400) 
                    });
            }
        }
        
        private function _onLeft(value:Number):void
        {
            _left = value;
        }
        
        private function _onRight(value:Number):void
        {
            _right = value;
        }
        
        private function _onUp(value:Number):void
        {
            _up = value;
        }
        
        private function _onDown(value:Number):void
        {
            _down = value;
        }
        
        private var _left:Number = 0;
        private var _right:Number = 0;
        private var _up:Number = 0;
        private var _down:Number = 0;
    }
}