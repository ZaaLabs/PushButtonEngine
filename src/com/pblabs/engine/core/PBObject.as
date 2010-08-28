/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.core
{
    import com.pblabs.engine.pb_internal;

    use namespace pb_internal;
    
    /**
     * Base implementation of a named object that can exist in PBSets or PBGroups.
     * 
     * @see IPBObject
     */
    public class PBObject implements IPBObject
    {
        protected var _name:String, _alias:String;
        protected var _owningGroup:PBGroup;
        protected var _sets:Array;
		protected var _context:PBContextBase;
        
		internal function setContext(c:PBContextBase):void
		{
			if(_context)
				throw new Error("Trying to set context on a PBObject that already has one!");
			_context = c;
		}
		
        internal function noteInSet(s:PBSet):void
        {
            if(!_sets)
                _sets = [];
            if(_sets.indexOf(s) != -1)
                return;      
            _sets.push(s);
        }
        
        internal function noteOutOfSet(s:PBSet):void
        {
            var idx:int = _sets.indexOf(s);
            if(idx == -1)
                throw new Error("Removed object from set that it isn't in.");
            _sets.splice(idx, 1);
        }
        
        public function get owningGroup():PBGroup
        {
            return _owningGroup;
        }

        public function set owningGroup(value:PBGroup):void
        {
			if(value == _owningGroup)
				return;
			
            if(!value)
                throw new Error("Must always be in a group - cannot set owningGroup to null!");
            
            if(_owningGroup)
                _owningGroup.removeFromGroup(this);
            
            _owningGroup = value;
            _owningGroup.addToGroup(this);
        }

        public function get name():String
        {
            return _name;
        }
        
        public function get alias():String
        {
            return _alias;
        }

        public function initialize(name:String = null, alias:String = null):void
        {           
            // Note the names.
            _name = name;
            _alias = alias;

			_context.register(this);
        }
        
        public function destroy():void
        {
			_context.unregister(this);
            
            // Remove from any sets.
            while(_sets && _sets.length)
            {
                // remove() cuts us from the list.
                // Note - if it returned false, we weren't in the set, so remove
                // set membership on our end. This is usually an artifact of
                // the set removing us from itself.
                if(_sets[_sets.length-1].remove(this) == false)
                    _sets.pop();
            }

            // Remove from our owning group.
            if(_owningGroup)
            {
                _owningGroup.removeFromGroup(this);
                _owningGroup = null;                
            }
        }
        
        public function get context():IPBContext
        {
            return _context;
        }
    }
}