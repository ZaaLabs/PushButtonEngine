package com.pblabs.engine.util
{
    import com.pblabs.engine.PBUtil;
    import com.pblabs.engine.serialization.TypeUtility;
    
    import flash.utils.Dictionary;

    public final class ObjectPooler
    {
        protected static const _typeDictionary:Dictionary = new Dictionary();
        
        public static function preallocate(type:Class, count:int):void
        {
            if(!_typeDictionary[type])
                _typeDictionary[type] = new ObjectPool(true);
            const pool:ObjectPool = _typeDictionary[type] as ObjectPool;

            pool.allocate(count, type);
        }
        
        public static function allocate(type:Class):*
        {
            if(!_typeDictionary[type])
                _typeDictionary[type] = new ObjectPool(true);
            const pool:ObjectPool = _typeDictionary[type] as ObjectPool;
            
            return pool.object;
        }
        
        public static function free(item:*, type:Class = null):void
        {
            if(type == null)
                type = TypeUtility.getClass(item);
            
            if(!_typeDictionary[type])
                _typeDictionary[type] = new ObjectPool(true);
            const pool:ObjectPool = _typeDictionary[type] as ObjectPool;
            
            pool.object = item;
        }
    }
}