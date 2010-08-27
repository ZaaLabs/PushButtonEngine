package com.pblabs.engine.core
{
   import com.pblabs.engine.PBE;
   import com.pblabs.engine.PBUtil;
   import com.pblabs.engine.debug.Logger;
   import com.pblabs.engine.input.InputKey;
   import com.pblabs.engine.input.InputManager;
   import com.pblabs.engine.pb_internal;
   import com.pblabs.engine.prefs.IPrefsManager;
   import com.pblabs.engine.resource.Resource;
   import com.pblabs.engine.resource.ResourceManager;
   import com.pblabs.engine.serialization.LevelManager;
   import com.pblabs.engine.serialization.Serializer;
   import com.pblabs.engine.serialization.TemplateManager;
   import com.pblabs.engine.time.IProcessManager;
   import com.pblabs.engine.util.version.VersionDetails;
   import com.pblabs.engine.util.version.VersionUtil;
   import com.pblabs.rendering.IScene;
   import com.pblabs.rendering.ISpatialManager;
   import com.pblabs.screens.ScreenManager;
   import com.pblabs.sound.ISoundManager;
   
   import flash.display.DisplayObject;
   import flash.display.LoaderInfo;
   import flash.display.Stage;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.utils.Dictionary;
   
   import org.swiftsuspenders.Injector;

   use namespace pb_internal;

   public class PBContextBase extends EventDispatcher implements IPBContextRegistration
   {
      protected static var contextNameCounter:int = 0;

      protected var _main:DisplayObject = null;

      private var _managers:Dictionary = new Dictionary();

      private var _rootGroup:PBGroup = null, _currentGroup:PBGroup = null;

      private var _stageQualityStack:Array = [];

      private var _versionDetails:VersionDetails;

      private var _name:String = null;

      public function PBContextBase(mainInstance:DisplayObject = null, name:String = null):void
      {
         if (mainInstance)
            startup(mainInstance, name);
      }

      protected function initializeName():void
      {
         contextNameCounter++;
         _name = "Context" + contextNameCounter;
      }

      public function get name():String
      {
         return _name;
      }
      
      public function startup(mainInstance:DisplayObject, name:String = null):void
      {
         if (!name)
            initializeName();
         else
            _name = name;

         _main = mainInstance;

         Logger.print(this, "Initializing PushButton Engine Context '" + _name + "'.");

         PBE.registerContext(this);

         Logger.startup();

         // Register ourselves.
         registerManager(IPBContext, this);

         // Do manager startup.
         initializeManagers();

         // Set up root and current group.
         var rg:PBGroup = allocateGroup();
         rg.initialize("RootGroup");
         _currentGroup = _rootGroup = rg;

         // Allow injection on main class, too.
         inject(mainInstance);
      }

      protected function initializeManagers():void
      {
         throw new Error("Child class should implement this.");
      }

      public function shutdown():void
      {
         // Subclasses could do something with the managers.
      }

      public function get started():Boolean
      {
         return _main != null;
      }

      public function registerManager(clazz:Class, instance:Object, optionalName:String = null):void
      {
         _managers[clazz + "" + optionalName] = instance;
      }

      public function getManager(clazz:Class, optionalName:String = null):*
      {
         return _managers[clazz + "" + optionalName];
      }

      public function inject(instance:*):void
      {
      }

      public function allocate(type:Class):*
      {
         var res:* = new type();

         var iec:IEntityComponent = res as IEntityComponent;
         var ipbo:PBObject = res as PBObject;

         if (iec)
            iec.context = this;
         else if (ipbo)
            ipbo.setContext(this);

         return res;
      }

      public function allocateEntity():IEntity
      {
         return allocate(Entity);
      }

      public function get rootGroup():PBGroup
      {
         return _rootGroup;
      }

      public function get currentGroup():PBGroup
      {
         return _currentGroup;
      }

      public function set currentGroup(value:PBGroup):void
      {
         if (value == null)
            throw new Error("You cannot set the currentGroup to null; it must always be a valid PBGroup.");

         if (value.context != this)
            throw new Error("Cannot mix objects between contexts.");

         _currentGroup = value;
      }

      public function register(object:IPBObject):void
      {
         // Register with the NameManager.
         nameManager.add(object);

         // Add to default group when appropriate.
         if (object.owningGroup == null)
         {
            if (_currentGroup)
            {
               object.owningGroup = _currentGroup;
            }
            else
            {
               if (_rootGroup)
                  throw new Error("Had null currentGroup while rootGroup is valid; currentGroup should always be a value, and should be rootGroup by default.");
            }
         }
      }

      public function unregister(object:IPBObject):void
      {
         // Clear out the NameManager.
         nameManager.remove(object);
      }

      public function get eventDispatcher():IEventDispatcher
      {
         return this as IEventDispatcher;
      }

      public function get mainClass():*
      {
         return _main;
      }

      public function get mainStage():Stage
      {
         return _main.stage;
      }

      public function get flashVars():Object
      {
         return LoaderInfo(_main.loaderInfo).parameters;
      }

      public function get hostingDomain():String
      {
         // Get at the hosting domain.
         var urlString:String = _main.stage.loaderInfo.url;
         var urlParts:Array = urlString.split("://");
         var wwwPart:Array = urlParts[1].split("/");
         if (wwwPart.length)
            return wwwPart[0];
         else
            return "[unknown]";
      }

      public function get versionDetails():VersionDetails
      {
         if (!_versionDetails)
            _versionDetails = VersionUtil.checkVersion(_main);

         return _versionDetails;
      }

      public function findChild(name:String):DisplayObject
      {
         return PBUtil.findChild(name, mainClass);
      }

      public function lookup(name:String):IPBObject
      {
         return nameManager.lookup(name) as IPBObject;
      }

      public function lookupEntity(name:String):IEntity
      {
         return nameManager.lookup(name) as IEntity;
      }

      public function lookupComponent(entityName:String, componentName:String):IEntityComponent
      {
         return nameManager.lookupComponentByName(entityName, componentName);
      }

      public function schedule(delay:Number, func:Function, args:Array):void
      {
         //processManager.schedule(delay, null, func, arg);
      }

      public function callLater(func:Function, args:Array):void
      {
         processManager.callLater(func, args);
      }

      public function log(reporter:*, text:String):void
      {
         Logger.print(reporter, text);
      }

      public function load(filename:String, resourceType:Class, onLoaded:Function = null, onFailed:Function = null, forceReload:Boolean = false):Resource
      {
         return resourceManager.load(filename, resourceType, onLoaded, onFailed, forceReload);
      }

      public function get processManager():IProcessManager
      {
         return getManager(IProcessManager);
      }

      public function get nameManager():NameManager
      {
         return getManager(NameManager);
      }

      public function get objectTypeManager():ObjectTypeManager
      {
         return getManager(ObjectTypeManager);
      }

      public function get inputManager():InputManager
      {
         return getManager(InputManager);
      }

      public function get soundManager():ISoundManager
      {
         return getManager(ISoundManager);
      }

      public function get resourceManager():ResourceManager
      {
         return getManager(ResourceManager);
      }

      public function get screenManager():ScreenManager
      {
         return getManager(ScreenManager);
      }

      public function get scene():IScene
      {
         return getManager(IScene);
      }

      public function get spatialManager():ISpatialManager
      {
         return getManager(ISpatialManager);
      }

      public function get levelManager():LevelManager
      {
         return getManager(LevelManager);
      }

      public function get templateManager():TemplateManager
      {
         return getManager(TemplateManager);
      }

      public function get prefsManager():IPrefsManager
      {
         return getManager(IPrefsManager);
      }

      public function get serializer():Serializer
      {
         return getManager(Serializer);
      }

      public function isKeyDown(key:InputKey):Boolean
      {
         if (!inputManager)
            return false;

         return inputManager.isKeyDown(key.keyCode);
      }

      public function wasKeyPressed(key:InputKey):Boolean
      {
         return inputManager.keyJustPressed(key.keyCode);
      }

      public function wasKeyReleased(key:InputKey):Boolean
      {
         return inputManager.keyJustReleased(key.keyCode);
      }

      public function isAnyKeyDown():Boolean
      {
         return inputManager.isAnyKeyDown();
      }

      /**
       * Set stage quality to a new value, and store the old value so we
       * can restore it later. Useful if you want to temporarily toggle
       * render quality.
       *
       * @param newQuality From StafeQuality, new quality level to use.
       */
      public function pushStageQuality(newQuality:String):void
      {
         _stageQualityStack.push(mainStage.quality);
         mainStage.quality = newQuality;
      }

      /**
       * Restore stage quality to previous value.
       *
       * @see pushStageQuality
       */
      public function popStageQuality():void
      {
         if (_stageQualityStack.length == 0)
            throw new Error("Bottomed out in stage quality stack! You have mismatched push/pop calls!");

         mainStage.quality = _stageQualityStack.pop();
      }

      public function makeEntity(entityName:String, params:Object = null):IEntity
      {
         // Create the entity.
         var entity:IEntity = templateManager.instantiateEntity(entityName);
         if (!entity)
            return null;

         if (!params)
            return entity;

         // Set all the properties.
         for (var key:* in params)
         {
            if (key is PropertyReference)
            {
               // Fast case.
               entity.setProperty(key, params[key]);
            }
            else if (key is String)
            {
               // Slow case.
               // Special case to allow "@foo": to assign foo as a new component... named foo.
               if (String(key).charAt(0) == "@" && String(key).indexOf(".") == -1)
               {
                  entity.addComponent(IEntityComponent(params[key]), String(key).substring(1));
               }
               else
               {
                  entity.setProperty(new PropertyReference(key), params[key]);
               }
            }
            else
            {
               // Error case.
               Logger.error(PBE, "MakeEntity", "Unexpected key '" + key + "'; can only handle String or PropertyReference.");
            }
         }

         // Finish deferring.
         if (entity.deferring)
            entity.deferring = false;

         // Give it to the user.
         return entity;
      }

   }
}