/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 * 
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine
{
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.engine.serialization.TypeUtility;
    import com.pblabs.engine.util.version.VersionDetails;
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Stage;
    import flash.geom.Matrix;
    import flash.utils.Dictionary;
    import flash.utils.describeType;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
    /**
     * Contains math related utility methods.
     */
    public class PBUtil
    {
        public static const FLIP_HORIZONTAL:String = "flipHorizontal";
        public static const FLIP_VERTICAL:String = "flipVertical";
        
        /**
         * Two times PI. 
         */
        public static const TWO_PI:Number = 2.0 * Math.PI;
        
        /**
         * Converts an angle in radians to an angle in degrees.
         * 
         * @param radians The angle to convert.
         * 
         * @return The converted value.
         */
        public static function getDegreesFromRadians(radians:Number):Number
        {
            return radians * 180 / Math.PI;
        }
        
        /**
         * Converts an angle in degrees to an angle in radians.
         * 
         * @param degrees The angle to convert.
         * 
         * @return The converted value.
         */
        public static function getRadiansFromDegrees(degrees:Number):Number
        {
            return degrees * Math.PI / 180;
        }
        
        /**
         * Keep a number between a min and a max.
         */
        public static function clamp(v:Number, min:Number = 0, max:Number = 1):Number
        {
            if(v < min) return min;
            if(v > max) return max;
            return v;
        }
        
        /**
         * Clones an array.
         * @param array Array to clone.
         * @return a cloned array.
         */
        public static function cloneArray(array:Array):Array
        {
            var newArray:Array = [];
            
            for each (var item:* in array)
            newArray.push(item);
            
            return newArray;
        }
        
        /**
         * Take a radian measure and make sure it is between -pi..pi. 
         */
        public static function unwrapRadian(r:Number):Number 
        { 
            r = r % TWO_PI;
            if (r > Math.PI) 
                r -= TWO_PI; 
            if (r < -Math.PI) 
                r += TWO_PI; 
            return r; 
        } 
        
        /**
         * Take a degree measure and make sure it is between -180..180.
         */
        public static function unwrapDegrees(r:Number):Number
        {
            r = r % 360;
            if (r > 180)
                r -= 360;
            if (r < -180)
                r += 360;
            return r;
        }
        
        /**
         * Return the shortest distance to get from from to to, in radians.
         */
        public static function getRadianShortDelta(from:Number, to:Number):Number
        {
            // Unwrap both from and to.
            from = unwrapRadian(from);
            to = unwrapRadian(to);
            
            // Calc delta.
            var delta:Number = to - from;
            
            // Make sure delta is shortest path around circle.
            if(delta > Math.PI)
                delta -= Math.PI * 2;            
            if(delta < -Math.PI)
                delta += Math.PI * 2;            
            
            // Done
            return delta;
        }
        
        /**
         * Return the shortest distance to get from from to to, in degrees.
         */
        public static function getDegreesShortDelta(from:Number, to:Number):Number
        {
            // Unwrap both from and to.
            from = unwrapDegrees(from);
            to = unwrapDegrees(to);
            
            // Calc delta.
            var delta:Number = to - from;
            
            // Make sure delta is shortest path around circle.
            if(delta > 180)
                delta -= 360;            
            if(delta < -180)
                delta += 360;            
            
            // Done
            return delta;
        }
        
        /**
         * Get number of bits required to encode values from 0..max.
         *
         * @param max The maximum value to be able to be encoded.
         * @return Bitcount required to encode max value.
         */
        public static function getBitCountForRange(max:int):int
        {
            var count:int = 0;
            
            // Unfortunately this is a bug with this method... and requires this special
            // case (same issue with the old method log calculation)
            if (max == 1) return 1;
            
            max--;
            while (max >> count > 0) count++;
            return count;
        }
        
        /**
         * Pick an integer in a range, with a bias factor (from -1 to 1) to skew towards
         * low or high end of range.
         *  
         * @param min Minimum value to choose from, inclusive.
         * @param max Maximum value to choose from, inclusive.
         * @param bias -1 skews totally towards min, 1 totally towards max.
         * @return A random integer between min/max with appropriate bias.
         * 
         */
        public static function pickWithBias(min:int, max:int, bias:Number = 0):int
        {
            return clamp((((Math.random() + bias) * (max - min)) + min), min, max);
        }
        
        /**
         * Assigns parameters from source to destination by name.
         * 
         * <p>This allows duck typing - you can accept a generic object
         * (giving you nice {foo:bar} syntax) and cast to a typed object for
         * easier internal processing and validation.</p>
         * 
         * @param source Object to read fields from.
         * @param destination Object to assign fields to.
         * @param abortOnMismatch If true, throw an error if a field in source is absent in destination.
         * @param deepCopy If true, check for arrays of objects in the source object and copy them as well
         */
        public static function duckAssign(source:Object, destination:Object, abortOnMismatch:Boolean = false, deepCopy:Boolean = false):void
        {
            // Get the list of public fields.
            var sourceFields:XML = TypeUtility.getTypeDescription(source);
            
            for each(var fieldInfo:XML in sourceFields.*)
            {
                // Skip anything that is not a field.
                if(fieldInfo.name() != "variable" && fieldInfo.name() != "accessor")
                    continue;
                
                // Skip write-only stuff.
                if(fieldInfo.@access == "writeonly")
                    continue;
                
                var fieldName:String = fieldInfo.@name;
                
                attemptAssign(fieldName, source, destination, abortOnMismatch, deepCopy);
            }
            
            // Deal with dynamic fields, too.
            for(var field:String in source)
            {
                attemptAssign(field, source, destination, abortOnMismatch, deepCopy);
            }
        }
        
        /**
         * Assign a single field from the source object to the destination. Also handles assigning
         * nested typed vectors of objects. In the destination object class, add a TypeHint to the 
         * field that contains the Vector like so:
         * 
         * [TypeHint (type="mygame.Item")]
         * public var parts:Vector.<Item>;
         * 
         * @param source Object to read fields from.
         * @param dest Object to assign fields to.
         * @param abortOnMismatch If true, throw an error if a field in source is absent in destination.
         * @param deepCopy If true, check for arrays of objects in the source object and copy them as well
         */
        private static function attemptAssign(fieldName:String, source:Object, destination:Object, abortOnMismatch:Boolean, deepCopy:Boolean):void
        {    
            // Deep copy and source is an array?
            if (deepCopy && source[fieldName] is Array)
            {
                var tmpArray:Object=null;
                
                // See if we have a type hint for objects in the array
                // by looking at the destination field
                var typeName:String = TypeUtility.getTypeHint(destination,fieldName);
                
                if (typeName)
                {
                    var vectorType:String = "Vector.<"+typeName+">";
                    tmpArray = TypeUtility.instantiate(vectorType);
                    
                    for each (var val:Object in source[fieldName])
                    {
                        var obj:Object = null;
                        if (typeName)
                        {
                            obj = TypeUtility.instantiate(typeName);
                        }                
                        else
                        {
                            obj = new Object();
                        }
                        
                        duckAssign(val, obj, abortOnMismatch, deepCopy);
                        
                        tmpArray.push(obj);
                    }
                }
                else
                {
                    tmpArray = source[fieldName];
                }
                
                
                destination[fieldName] = tmpArray;                    
            }
            else
            {
                try
                {
                    // Try to assign.
                    destination[fieldName] = source[fieldName];
                }
                catch(e:Error)
                {
                    // Abort or continue, depending on user settings.
                    if(!abortOnMismatch)
                        return;
                    throw new Error("Field '" + fieldName + "' in source was not present in destination.");
                }
            }
        }
        
        /**
         * Calculate length of a vector. 
         */
        public static function xyLength(x:Number, y:Number):Number
        {
            return Math.sqrt((x*x)+(y*y));
        }
        
        /**
         * Replaces instances of less then, greater then, ampersand, single and double quotes.
         * @param str String to escape.
         * @return A string that can be used in an htmlText property.
         */        
        public static function escapeHTMLText(str:String):String
        {
            var chars:Array = 
                [
                    {char:"&", repl:"|amp|"},
                    {char:"<", repl:"&lt;"},
                    {char:">", repl:"&gt;"},
                    {char:"\'", repl:"&apos;"},
                    {char:"\"", repl:"&quot;"},
                    {char:"|amp|", repl:"&amp;"}
                ];
            
            for(var i:int=0; i < chars.length; i++)
            {
                while(str.indexOf(chars[i].char) != -1)
                {
                    str = str.replace(chars[i].char, chars[i].repl);
                }
            }
            
            return str;
        }
        
        /**
         * Converts a String to a Boolean. This method is case insensitive, and will convert 
         * "true", "t" and "1" to true. It converts "false", "f" and "0" to false.
         * @param str String to covert into a boolean. 
         * @return true or false
         */        
        public static function stringToBoolean(str:String):Boolean
        {
            switch(str.substring(1, 0).toUpperCase())
            {
                case "F":
                case "0":
                    return false;
                    break;
                case "T":
                case "1":
                    return true;
                    break;
            }
            
            return false;
        }
        
        /**
         * Capitalize the first letter of a string 
         * @param str String to capitalize the first leter of
         * @return String with the first letter capitalized.
         */        
        public static function capitalize(str:String):String
        {
            return str.substring(1, 0).toUpperCase() + str.substring(1);
        }
        
        /**
         * Removes all instances of the specified character from 
         * the beginning and end of the specified string.
         */
        public static function trim(str:String, char:String):String {
            return trimBack(trimFront(str, char), char);
        }
        
        /**
         * Recursively removes all characters that match the char parameter, 
         * starting from the front of the string and working toward the end, 
         * until the first character in the string does not match char and returns 
         * the updated string.
         */        
        public static function trimFront(str:String, char:String):String
        {
            char = stringToCharacter(char);
            if (str.charAt(0) == char) {
                str = trimFront(str.substring(1), char);
            }
            return str;
        }
        
        /**
         * Recursively removes all characters that match the char parameter, 
         * starting from the end of the string and working backward, 
         * until the last character in the string does not match char and returns 
         * the updated string.
         */        
        public static function trimBack(str:String, char:String):String
        {
            char = stringToCharacter(char);
            if (str.charAt(str.length - 1) == char) {
                str = trimBack(str.substring(0, str.length - 1), char);
            }
            return str;
        }
        
        /**
         * Returns the first character of the string passed to it. 
         */        
        public static function stringToCharacter(str:String):String 
        {
            if (str.length == 1) {
                return str;
            }
            return str.slice(0, 1);
        }
        
        /**
         * Determine the file extension of a file. 
         * @param file A path to a file.
         * @return The file extension.
         * 
         */
        public static function getFileExtension(file:String):String
        {
            var extensionIndex:Number = file.lastIndexOf(".");
            if (extensionIndex == -1) {
                //No extension
                return "";
            } else {
                return file.substr(extensionIndex + 1,file.length);
            }
        }
        
        /**
         * Method for flipping a DisplayObject 
         * @param obj DisplayObject to flip
         * @param orientation Which orientation to use: PBUtil.FLIP_HORIZONTAL or PBUtil.FLIP_VERTICAL
         * 
         */        
        public static function flipDisplayObject(obj:DisplayObject, orientation:String):void
        {
            var m:Matrix = obj.transform.matrix;
             
            switch (orientation) 
            {
                case FLIP_HORIZONTAL:
                    m.a = -1 * m.a;
                    m.tx = obj.width + obj.x;
                    break;
                case FLIP_VERTICAL:
                    m.d = -1 * m.d;
                    m.ty = obj.height + obj.y;
                    break;
            }
            
            obj.transform.matrix = m;
        }
        
        public static var dumpRecursionSafety:Dictionary = new Dictionary();
        
        /**
         * Log an object to the console. Based on http://dev.base86.com/solo/47/actionscript_3_equivalent_of_phps_printr.html 
         * @param thisObject Object to display for logging.
         * @param obj Object to dump.
         */
        public static function dumpObjectToLogger(thisObject:*, obj:*, level:int = 0, output:String = ""):String
        {
            var tabs:String = "";
            for(var i:int = 0; i < level; i++) 
                tabs += "\t";
            
            var fields:Array = TypeUtility.getListOfPublicFields(obj);
            
            for each(var child:* in fields) 
            {
                // Only dump things once.
                if(dumpRecursionSafety[child] == 1)
                    continue;
                dumpRecursionSafety[child] = 1;
                
                output += tabs +"["+ child +"] => "+ obj[child];
                
                var childOutput:String = dumpObjectToLogger(thisObject, obj[child], level+1);
                if(childOutput != '') output += ' {\n'+ childOutput + tabs +'}';
                
                output += "\n";
            }
            
            if(level == 0)
            {
                // Clear the recursion safety net.
                dumpRecursionSafety = new Dictionary();
                
                Logger.print(thisObject, output);
                return "";
            }
            
            return output;
        }
        
        /**
         * Make a deep copy of an object.
         * 
         * Only really works well with all-public objects, private/protected
         * fields will not be respected.
         *  
         * @param source Object to copy.
         * @return New instance of object with all public fields set.
         * 
         */
        public static function clone(source:Object):Object 
        {
            var clone:Object;
            if(!source)
                return null;
            
            clone = newSibling(source);
            
            if(clone) 
                copyData(source, clone);
            
            return clone;
        }
        
        protected static function newSibling(sourceObj:Object):* 
        {
            if(!sourceObj)
                return null;
            
            var objSibling:*;
            try 
            {
                var classOfSourceObj:Class = getDefinitionByName(getQualifiedClassName(sourceObj)) as Class;
                objSibling = new classOfSourceObj();
            }
            catch(e:Object) 
            {
            }
            
            return objSibling;
        }
        
        protected static function copyData(source:Object, destination:Object):void 
        {
            
            //copies data from commonly named properties and getter/setter pairs
            if((source) && (destination)) 
            {
                try {
                    var sourceInfo:XML = describeType(source);
                    var prop:XML;
                    
                    for each(prop in sourceInfo.variable) 
                    {
                        if(!destination.hasOwnProperty(prop.@name))
                            continue;
                        destination[prop.@name] = source[prop.@name];
                    }
                    
                    for each(prop in sourceInfo.accessor) 
                    {
                        if(prop.@access != "readwrite")
                            continue;
                        
                        if(!destination.hasOwnProperty(prop.@name)) 
                            continue;
                        
                        destination[prop.@name] = source[prop.@name];
                    }
                }
                catch (err:Object) 
                {
                }
            }
        }
        
        /**
         * Recursively searches for an object with the specified name that has been added to the
         * display hierarchy.
         * 
         * @param name The name of the object to find.
         * 
         * @return The display object with the specified name, or null if it wasn't found.
         */
        public static function findChild(name:String, displayObjectToSearch:DisplayObject):DisplayObject
        {
            return _findChild(name, displayObjectToSearch);
        }
        
        protected static function _findChild(name:String, current:DisplayObject):DisplayObject
        {
            if (!current)
                return null;
            
            if (current.name == name)
                return current;
            
            var parent:DisplayObjectContainer = current as DisplayObjectContainer;
            
            if (!parent)
                return null;
            
            for (var i:int = 0; i < parent.numChildren; i++)
            {
                var child:DisplayObject = _findChild(name, parent.getChildAt(i));
                if (child)
                    return child;
            }
            
            return null;
        }
        
        /**
         * Return a function that calls a specified function with the provided arguments.
         * 
         * For instance, function a(b,c) through closurize(a, b, c) becomes 
         * a function() that calls function a(b,c);
         * 
         * Thanks to Rob Sampson <www.calypso88.com>.
         */
        public static function closurize(func:Function, ...args):Function
        {
            // Create a new function...
            return function():* 
            {
                // Call the original function with provided args.
                return func.apply(null, args);
            }
        }
        
        /**
         * Return a function that calls a specified function with the provided arguments
         * APPENDED to its provided arguments.
         * 
         * For instance, function a(b,c) through closurizeAppend(a, c) becomes 
         * a function(b) that calls function a(b,c);
         */
        public static function closurizeAppend(func:Function, ...additionalArgs):Function
        {
            // Create a new function...
            return function(...localArgs):* 
            {
                // Combine parameter lists.
                var argsCopy:Array = localArgs.concat(additionalArgs);
                
                // Call the original function.
                return func.apply(null, argsCopy);
            }
        }
        
        /**
         * Return a sorted list of the keys in a dictionary
         */
        public static function getSortedDictionaryKeys(dict:Object):Array
        {
            var keylist:Array = new Array();
            for (var key:String in dict)
            {
                keylist.push(key);
            }
            keylist.sort();
            
            return keylist;
        }
        
        /**
         * Return a sorted list of the values in a dictionary
         */
        public static function getSortedDictionaryValues(dict:Dictionary):Array
        {
            var valuelist:Array = new Array();
            for each (var value:Object in dict)
            {
                valuelist.push(value);
            }
            valuelist.sort();
            
            return valuelist;
        }
        
        protected var _stageQualityStack:Array = [];
        
        /**
         * Set stage quality to a new value, and store the old value so we
         * can restore it later. Useful if you want to temporarily toggle
         * render quality.
         *
         * @param newQuality From StafeQuality, new quality level to use.
         */
        public function pushStageQuality(mainStage:Stage, newQuality:String):void
        {
            _stageQualityStack.push(mainStage.quality);
            mainStage.quality = newQuality;
        }
        
        /**
         * Restore stage quality to previous value.
         *
         * @see pushStageQuality
         */
        public function popStageQuality(mainStage:Stage):void
        {
            if (_stageQualityStack.length == 0)
                throw new Error("Bottomed out in stage quality stack! You have mismatched push/pop calls!");
            
            mainStage.quality = _stageQualityStack.pop();
        }
        
        protected static var callLaterQueue:Array = [];
        
        /**
         * Deferred function callback - called back at start of processing for next frame. Useful
         * any time you are going to do setTimeout(someFunc, 1) - it's a lot cheaper to do it 
         * this way.
         * @param method Function to call.
         * @param args Any arguments.
         */
        public static function callLater(method:Function, args:Array = null):void
        {
            var dm:DeferredMethod = new DeferredMethod();
            dm.method = method;
            dm.args = args;
            callLaterQueue.push(dm);            
        }
        
        public static function processCallLaters():void
        {
            // Do any deferred methods.
            var oldCallLaterQueue:Array = callLaterQueue;
            if(oldCallLaterQueue.length)
            {
                // Put a new array in the queue to avoid getting into corrupted
                // state due to more calls being added.
                callLaterQueue = [];
                
                for(var j:int=0; j<oldCallLaterQueue.length; j++)
                {
                    var curDM:DeferredMethod = oldCallLaterQueue[j] as DeferredMethod;
                    curDM.method.apply(null, curDM.args);
                }
                
                // Wipe the old array now we're done with it.
                oldCallLaterQueue.length = 0;
            }            
        }
    }
}

final class DeferredMethod
{
    public var method:Function = null;;
    public var args:Array = null;
}