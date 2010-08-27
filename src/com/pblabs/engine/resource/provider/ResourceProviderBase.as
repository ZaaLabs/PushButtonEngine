/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.resource.provider
{
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.engine.resource.Resource;
    import com.pblabs.engine.resource.ResourceManager;
    
    import flash.utils.Dictionary;
    
    /**
     * The ResourceProviderBase class provides useful functionality for implementing
     * resource providers for the ResourceManager.
     * 
     * Register a ResourceProvider by doing resourceManager.registerResourceProvider(new MyProvider());
     */
    public class ResourceProviderBase implements IResourceProvider
    {
        /**
         * Storage of resources known by this provider.
         */
        protected var resources:Dictionary = new Dictionary();

        /**
         * This method will check if this provider has access to a specific Resource
         */
        public function isResourceKnown(uri:String, type:Class):Boolean
        {
            var resourceIdentifier:String = uri.toLowerCase() + type;
            return (resources[resourceIdentifier] != null);
        }
        
        /**
         * This method will request a resource from this ResourceProvider
         */
        public function getResource(uri:String, type:Class, forceReload:Boolean = false):Resource
        {
            var resourceIdentifier:String = uri.toLowerCase() + type;
            return resources[resourceIdentifier];
        }
        
        /**
         * This method will add a resource to the resource's Dictionary
         */
        protected function addResource(uri:String, type:Class, resource:Resource):void
        {
            var resourceIdentifier:String = uri.toLowerCase() + type;
            resources[resourceIdentifier] = resource;            
        }
        
        public function setPriority(resource:Resource, priority:Number):void
        {
            Logger.warn(this, "setPriority", "No priority support in this resource provider.");
        }
        
        public function cancel(resource:Resource):void
        {
            Logger.warn(this, "cancel", "No cancel support in this resource provider.");
        }
    }
}