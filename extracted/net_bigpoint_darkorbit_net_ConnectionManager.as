package net.bigpoint.darkorbit.net
{
   import com.bigpoint.utils.BPLocale;
   import com.greensock.TweenMax;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.DataEvent;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.events.TimerEvent;
   import flash.external.ExternalInterface;
   import flash.geom.Point;
   import flash.net.XMLSocket;
   import flash.system.Capabilities;
   import flash.system.System;
   import flash.text.TextField;
   import flash.utils.Timer;
   import mx.utils.StringUtil;
   import net.bigpoint.AmmoPrice;
   import net.bigpoint.darkorbit.CommandLog;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.InGameCatalog;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.audio.AudioManager;
   import net.bigpoint.darkorbit.catalog.SpecialAmmunition;
   import net.bigpoint.darkorbit.collectable.Collectable;
   import net.bigpoint.darkorbit.collectable.CollectablePattern;
   import net.bigpoint.darkorbit.combat.ExplosionPattern;
   import net.bigpoint.darkorbit.combat.RocketPattern;
   import net.bigpoint.darkorbit.gui.GuiManager;
   import net.bigpoint.darkorbit.gui.container.SimpleContainer;
   import net.bigpoint.darkorbit.gui.elements.SimpleElement;
   import net.bigpoint.darkorbit.gui.windows.SimpleWindow;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.map.MiniMap;
   import net.bigpoint.darkorbit.map.MinimapManager;
   import net.bigpoint.darkorbit.menu.ActionButton2;
   import net.bigpoint.darkorbit.menu.SuperActionButton;
   import net.bigpoint.darkorbit.menu.TopMenu;
   import net.bigpoint.darkorbit.pattern.EffectPattern;
   import net.bigpoint.darkorbit.pattern.OrePattern;
   import net.bigpoint.darkorbit.pattern.PatternManager;
   import net.bigpoint.darkorbit.pattern.ResourcePattern;
   import net.bigpoint.darkorbit.settings.Settings;
   import net.bigpoint.darkorbit.ship.BufferedShip;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.Ship;
   import net.bigpoint.darkorbit.ship.ShipManager;
   import net.bigpoint.darkorbit.ship.effects.BattleRepBotTechEffect;
   import net.bigpoint.darkorbit.ship.effects.EffectIDList;
   import net.bigpoint.darkorbit.ship.effects.EffectsManager;
   import net.bigpoint.darkorbit.ship.pet.Pet;
   import net.bigpoint.darkorbit.station.RelayStation;
   import net.bigpoint.darkorbit.station.Station;
   
   public class ConnectionManager
   {
      
      public static var ATTRIBUTE_SEPERATOR:String = "|";
      
      public static var LIST_SEPERATOR:String = ",";
      
      public static var PARAM_1:String = "%!";
      
      public static var PARAM_2:String = "%2!";
      
      private var lastConnectedServerIP:String;
      
      public var port:int = 8080;
      
      public var xmlSocket:XMLSocket;
      
      private var main:Main;
      
      private var pingTimer:Timer;
      
      public var bufferedShips:Array = [];
      
      public var _watchedShipInits:Object = {};
      
      private var lockedShip:MapObject;
      
      private var settingsAssembly:SettingsAssembly;
      
      private var uiAssembly:UserInterfaceAssembly;
      
      private var attributesAssembly:SetAttributeAssembly;
      
      private var techAssembly:TechAssembly;
      
      private var assetAssembly:AssetAssembly;
      
      private var boxCollectAssembly:BoxCollectResponseAssembly;
      
      private var rocketLauncherAssembly:RocketLauncherAssembly;
      
      private var groupSystemAssembly:GroupSystemAssembly;
      
      private var _isLoggingGameServerIO:Boolean;
      
      private var ioLogger:CommandLog;
      
      private var adminNetworkMonitorTimer:Timer;
      
      private var currentIPAddress:String;
      
      private var connectionMonitorTimer:Timer = new Timer(500,0);
      
      private var skillsAssembly:SkillsAssembly;
      
      private var petAssembly:PetAssembly;
      
      private var mapEventsAssembly:MapEventsAssembly;
      
      private var questAssembly:QuestAssembly;
      
      public var isMapLoaded:Boolean = false;
      
      public var isHeroLoaded:Boolean = false;
      
      private var poiAssembly:POIAssembly;
      
      private var effectsManager:EffectsManager = EffectsManager.getInstance();
      
      public function ConnectionManager(param1:Main)
      {
         super();
         this._isLoggingGameServerIO = false;
         this.main = param1;
         this.uiAssembly = UserInterfaceAssembly.getInstance();
         this.rocketLauncherAssembly = RocketLauncherAssembly.getInstance();
         this.attributesAssembly = SetAttributeAssembly.getInstance();
         this.boxCollectAssembly = BoxCollectResponseAssembly.getInstance();
         this.boxCollectAssembly.setParams(PARAM_1,PARAM_2);
         this.groupSystemAssembly = GroupSystemAssembly.getInstance();
         this.petAssembly = PetAssembly.getInstance();
         this.questAssembly = new QuestAssembly();
         this.questAssembly.setMain(param1);
      }
      
      private function handlePingTick(param1:TimerEvent) : void
      {
         this.sendCommand(ServerCommands.PING);
      }
      
      public function watchShipInit(param1:int) : void
      {
         this._watchedShipInits[param1] = true;
      }
      
      public function unwatchShipInit(param1:int) : void
      {
         delete this._watchedShipInits[param1];
      }
      
      public function connectToMap(param1:int) : void
      {
         var _mapID:int = param1;
         Settings.mapID = _mapID;
         if(this.main.screenManager.map != null)
         {
            this.main.screenManager.map.getStationManager().cleanup();
         }
         this.settingsAssembly = SettingsAssembly.getInstance();
         this.uiAssembly = UserInterfaceAssembly.getInstance();
         if(Settings.defaultGameServer != null)
         {
            this.connect(Settings.defaultGameServer);
         }
         else
         {
            this.connect(Main.mapsXML.map.(@id == _mapID).gameserverIP);
         }
      }
      
      private function handleConnectionLost(param1:Event) : void
      {
         var _loc2_:ShipManager = null;
         this.isHeroLoaded = false;
         this.main.getGroupManager().dispose();
         if(!Hero.isKilled)
         {
            if(this.main.getScheduledDisconnect())
            {
               this.connectToMap(Settings.nextMapID);
            }
            else
            {
               this.main.getGuiManager().removeConnectionWindow();
               this.main.getGuiManager().showConnectionLostWindow();
               if(this.main.screenManager.map != null)
               {
                  this.main.screenManager.map.getCollectableManager().cleanup();
               }
            }
         }
         this.petAssembly.assemblePetDeactivation();
         if(this.main.screenManager.map != null)
         {
            _loc2_ = this.main.screenManager.map.getShipManager();
            if(_loc2_.getHero() != null && _loc2_.getHero().pet != null)
            {
               _loc2_.removeOpponentShip(_loc2_.getHero().pet.userID);
            }
         }
      }
      
      public function connect(param1:String) : void
      {
         this.currentIPAddress = param1;
         this.stopConnectionMonitorTimer();
         if(this.xmlSocket != null)
         {
            this.xmlSocket.removeEventListener(Event.CONNECT,this.handleGameServerConnect);
            this.xmlSocket.removeEventListener(IOErrorEvent.IO_ERROR,this.handleGameServerIOError);
            this.xmlSocket.removeEventListener(DataEvent.DATA,this.onData);
            this.xmlSocket.removeEventListener(Event.CLOSE,this.handleConnectionLost);
            this.xmlSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,this.handleGameServerConnSecurityError);
            if(this.xmlSocket.connected)
            {
               this.xmlSocket.close();
            }
         }
         this.xmlSocket = new XMLSocket();
         this.xmlSocket.addEventListener(Event.CONNECT,this.handleGameServerConnect);
         this.xmlSocket.addEventListener(IOErrorEvent.IO_ERROR,this.handleGameServerIOError);
         this.xmlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.handleGameServerConnSecurityError);
         this.xmlSocket.addEventListener(DataEvent.DATA,this.onData);
         this.xmlSocket.addEventListener(Event.CLOSE,this.handleConnectionLost);
         this.xmlSocket.connect(param1,this.port);
         this.lastConnectedServerIP = param1;
      }
      
      private function handleGameServerConnSecurityError(param1:SecurityErrorEvent) : void
      {
         if(!this.xmlSocket.connected)
         {
            this.main.setScheduledDisconnect(false);
            this.handleConnectionLost(new Event(Event.CLOSE));
         }
      }
      
      private function startConnectionMonitorTimer() : void
      {
         this.connectionMonitorTimer.addEventListener(TimerEvent.TIMER,this.handleMonitorTick);
         this.connectionMonitorTimer.start();
      }
      
      private function stopConnectionMonitorTimer() : void
      {
         if(this.connectionMonitorTimer != null)
         {
            this.connectionMonitorTimer.stop();
            this.connectionMonitorTimer.removeEventListener(TimerEvent.TIMER,this.handleMonitorTick);
         }
      }
      
      private function handleMonitorTick(param1:TimerEvent) : void
      {
         if(this.xmlSocket.connected)
         {
            this.stopConnectionMonitorTimer();
         }
         else if(!Hero.isKilled)
         {
            this.main.setScheduledDisconnect(false);
            this.main.getGuiManager().showConnectionLostWindow();
            this.stopConnectionMonitorTimer();
         }
      }
      
      public function getLastConnectedServerIP() : String
      {
         return this.lastConnectedServerIP;
      }
      
      public function sendCommand(param1:String, param2:Array = null) : String
      {
         if(!this.xmlSocket.connected)
         {
            return "";
         }
         var _loc3_:String = param1;
         if(param2 != null)
         {
            _loc3_ += ATTRIBUTE_SEPERATOR + param2.join(ATTRIBUTE_SEPERATOR);
         }
         _loc3_ += "\n";
         this.xmlSocket.send(_loc3_);
         return _loc3_;
      }
      
      public function sendRawCommand(param1:String) : void
      {
         if(!this.xmlSocket.connected)
         {
            return;
         }
         if(param1.charAt(param1.length - 1) != "\n")
         {
            param1 += "\n";
         }
         if(this._isLoggingGameServerIO)
         {
         }
         this.xmlSocket.send(param1);
      }
      
      public function dispatchSpacemapLoaded() : void
      {
         if(this.isHeroLoaded && this.isMapLoaded)
         {
            this.sendCommand(ServerCommands.READY_COMMAND,[ServerCommands.SPACEMAP_LOADED]);
            if(Settings.displayNotifications)
            {
               this.main.getProfiler().start();
            }
         }
         this.main.getGuiManager().initDebugView();
      }
      
      public function handleGameServerConnect(param1:Event) : void
      {
         this.startConnectionMonitorTimer();
         var _loc2_:Array = [Hero.userID,Hero.sessionID,Main.version];
         if(Hero.factionID != 0 && Settings.mapID == 255)
         {
            _loc2_.push(Hero.factionID);
         }
         this.sendCommand("LOGIN",_loc2_);
         if(this.pingTimer == null)
         {
            this.pingTimer = new Timer(25000,0);
            this.pingTimer.addEventListener(TimerEvent.TIMER,this.handlePingTick);
            this.handlePingTick(null);
            this.pingTimer.start();
         }
      }
      
      public function handleGameServerIOError(param1:Event) : void
      {
         param1.stopPropagation();
         this.main.setScheduledDisconnect(false);
         this.handleConnectionLost(new Event(Event.CLOSE));
      }
      
      private function onData(param1:DataEvent) : void
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:Map = null;
         var _loc10_:Ship = null;
         var _loc11_:BufferedShip = null;
         var _loc12_:Number = NaN;
         var _loc13_:int = 0;
         var _loc14_:String = null;
         var _loc15_:Boolean = false;
         var _loc16_:int = 0;
         var _loc17_:int = 0;
         var _loc18_:String = null;
         var _loc19_:int = 0;
         var _loc20_:int = 0;
         var _loc21_:Number = NaN;
         var _loc22_:int = 0;
         var _loc23_:Number = NaN;
         var _loc24_:Number = NaN;
         var _loc25_:Number = NaN;
         var _loc26_:int = 0;
         var _loc27_:int = 0;
         var _loc28_:Number = NaN;
         var _loc29_:int = 0;
         var _loc30_:MapObject = null;
         var _loc31_:ShipManager = null;
         var _loc32_:int = 0;
         var _loc33_:Number = NaN;
         var _loc34_:String = null;
         var _loc35_:int = 0;
         var _loc36_:int = 0;
         var _loc37_:SimpleWindow = null;
         var _loc38_:String = null;
         var _loc39_:int = 0;
         var _loc40_:int = 0;
         var _loc41_:String = null;
         var _loc42_:String = null;
         var _loc43_:int = 0;
         var _loc44_:String = null;
         var _loc45_:int = 0;
         var _loc46_:String = null;
         var _loc47_:int = 0;
         var _loc48_:int = 0;
         var _loc49_:int = 0;
         var _loc50_:String = null;
         var _loc51_:int = 0;
         var _loc52_:String = null;
         var _loc53_:int = 0;
         var _loc54_:int = 0;
         var _loc55_:Boolean = false;
         var _loc56_:Array = null;
         var _loc57_:ExplosionPattern = null;
         var _loc58_:Collectable = null;
         var _loc59_:int = 0;
         var _loc60_:int = 0;
         var _loc61_:int = 0;
         var _loc62_:int = 0;
         var _loc63_:int = 0;
         var _loc65_:String = null;
         var _loc66_:GuiManager = null;
         var _loc67_:Boolean = false;
         var _loc68_:String = null;
         var _loc69_:String = null;
         var _loc70_:int = 0;
         var _loc71_:Boolean = false;
         var _loc72_:int = 0;
         var _loc73_:Boolean = false;
         var _loc74_:Boolean = false;
         var _loc75_:int = 0;
         var _loc76_:Boolean = false;
         var _loc77_:int = 0;
         var _loc78_:Boolean = false;
         var _loc79_:Boolean = false;
         var _loc80_:int = 0;
         var _loc81_:int = 0;
         var _loc82_:Boolean = false;
         var _loc83_:int = 0;
         var _loc84_:int = 0;
         var _loc85_:int = 0;
         var _loc86_:RelayStation = null;
         var _loc87_:int = 0;
         var _loc88_:RelayStation = null;
         var _loc89_:int = 0;
         var _loc90_:int = 0;
         var _loc91_:int = 0;
         var _loc92_:Boolean = false;
         var _loc93_:String = null;
         var _loc94_:Sprite = null;
         var _loc95_:int = 0;
         var _loc96_:int = 0;
         var _loc97_:int = 0;
         var _loc98_:int = 0;
         var _loc99_:TextField = null;
         var _loc100_:int = 0;
         var _loc101_:int = 0;
         var _loc102_:SimpleWindow = null;
         var _loc103_:Boolean = false;
         var _loc104_:Boolean = false;
         var _loc105_:Boolean = false;
         var _loc106_:Boolean = false;
         var _loc107_:Boolean = false;
         var _loc108_:int = 0;
         var _loc109_:ActionButton2 = null;
         var _loc110_:int = 0;
         var _loc111_:Array = null;
         var _loc112_:int = 0;
         var _loc113_:* = 0;
         var _loc114_:int = 0;
         var _loc115_:int = 0;
         var _loc116_:int = 0;
         var _loc117_:int = 0;
         var _loc118_:int = 0;
         var _loc119_:String = null;
         var _loc120_:Array = null;
         var _loc121_:Boolean = false;
         var _loc122_:Station = null;
         var _loc123_:int = 0;
         var _loc124_:int = 0;
         var _loc125_:Boolean = false;
         var _loc126_:Vector.<int> = null;
         var _loc127_:int = 0;
         var _loc128_:int = 0;
         var _loc129_:int = 0;
         var _loc130_:MovieClip = null;
         var _loc131_:String = null;
         var _loc132_:int = 0;
         var _loc133_:int = 0;
         var _loc134_:int = 0;
         var _loc135_:int = 0;
         var _loc136_:int = 0;
         var _loc137_:int = 0;
         var _loc138_:int = 0;
         var _loc139_:int = 0;
         var _loc140_:MapObject = null;
         var _loc141_:MapObject = null;
         var _loc142_:Point = null;
         var _loc143_:MinimapManager = null;
         var _loc144_:MiniMap = null;
         var _loc145_:int = 0;
         var _loc146_:SimpleWindow = null;
         var _loc147_:TopMenu = null;
         var _loc148_:ResourcePattern = null;
         var _loc149_:BattleRepBotTechEffect = null;
         var _loc150_:int = 0;
         var _loc151_:Boolean = false;
         var _loc152_:int = 0;
         var _loc153_:String = null;
         var _loc154_:Array = null;
         var _loc155_:int = 0;
         var _loc156_:Pet = null;
         var _loc157_:CollectablePattern = null;
         var _loc158_:int = 0;
         var _loc159_:int = 0;
         var _loc160_:int = 0;
         var _loc161_:String = null;
         var _loc162_:String = null;
         var _loc163_:Array = null;
         var _loc164_:int = 0;
         var _loc165_:int = 0;
         var _loc166_:int = 0;
         var _loc167_:int = 0;
         var _loc168_:AmmoPrice = null;
         var _loc169_:int = 0;
         var _loc170_:String = null;
         var _loc171_:int = 0;
         var _loc172_:int = 0;
         var _loc173_:int = 0;
         var _loc174_:int = 0;
         var _loc175_:uint = 0;
         var _loc2_:String = String(param1.data);
         _loc3_ = _loc2_.split(ATTRIBUTE_SEPERATOR);
         if(this._isLoggingGameServerIO)
         {
            _loc68_ = StringUtil.trim(_loc2_);
            _loc69_ = _loc68_.replace(/</g,"^").replace(/\>/g,"^");
         }
         var _loc64_:int = 0;
         switch(_loc3_[1])
         {
            case ServerCommands.PET:
               this.petAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.SHIP_MOVEMENT:
               _loc4_ = int(_loc3_[2]);
               _loc5_ = int(_loc3_[3]);
               _loc6_ = int(_loc3_[4]);
               _loc70_ = int(_loc3_[5]);
               _loc71_ = false;
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getShipManager().moveShip(_loc4_,_loc5_,_loc6_,_loc70_);
               }
               break;
            case ServerCommands.LASER_ATTACK:
               _loc7_ = int(_loc3_[2]);
               _loc8_ = int(_loc3_[3]);
               _loc72_ = int(_loc3_[4]);
               _loc73_ = Boolean(int(_loc3_[5]));
               _loc74_ = Boolean(int(_loc3_[6]));
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getCombatManager().addLaserAttack(_loc7_,_loc8_,_loc72_,_loc73_,_loc74_);
                  _loc140_ = _loc9_.getShipManager().getShip(_loc7_);
                  if(_loc140_ != null && _loc140_.energyLeechActive)
                  {
                     _loc9_.getCombatManager().addLaserAttack(_loc8_,_loc7_,7,false,false);
                  }
               }
               if(_loc7_ == Hero.userID)
               {
                  _loc10_ = _loc9_.getShipManager().getHero();
                  if(!_loc10_.shipPattern.playLoop)
                  {
                     _loc141_ = _loc9_.getShipManager().getShip(_loc8_);
                     _loc9_.getEventManager().heroLockToTarget = _loc141_;
                  }
               }
               break;
            case ServerCommands.HERO_MOVEMENT:
               _loc5_ = int(_loc3_[2]);
               _loc6_ = int(_loc3_[3]);
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc10_ = _loc9_.getShipManager().getHero();
                  if(_loc10_ != null)
                  {
                     _loc142_ = _loc9_.poiManager.checkPOIZoneCollisions(new Point(_loc10_.x,_loc10_.y),new Point(_loc5_,_loc6_));
                     if(_loc142_ != null)
                     {
                        _loc5_ = _loc142_.x;
                        _loc6_ = _loc142_.y;
                     }
                     _loc9_.getEventManager().moveHeroToCordinates(_loc5_,_loc6_);
                     _loc143_ = _loc9_.getMinimapManager();
                     if(_loc143_ != null)
                     {
                        _loc144_ = _loc143_.getMiniMap();
                        if(_loc144_ != null)
                        {
                           _loc144_.highlightRoute(_loc5_,_loc6_);
                        }
                     }
                  }
               }
               break;
            case ServerCommands.CREATE_SHIP:
               _loc4_ = int(_loc3_[2]);
               _loc29_ = int(_loc3_[3]);
               _loc75_ = int(_loc3_[4]);
               _loc14_ = _loc3_[5];
               _loc34_ = _loc3_[6];
               _loc26_ = int(_loc3_[7]);
               _loc27_ = int(_loc3_[8]);
               _loc19_ = int(_loc3_[9]);
               _loc13_ = int(_loc3_[10]);
               _loc16_ = int(_loc3_[11]);
               _loc76_ = Boolean(int(_loc3_[12]));
               _loc77_ = int(_loc3_[13]);
               _loc17_ = int(_loc3_[14]);
               _loc78_ = Boolean(int(_loc3_[16]));
               _loc15_ = Boolean(int(_loc3_[17]));
               if(_loc29_ == 84 || _loc29_ == 85)
               {
                  _loc75_ = 1;
               }
               _loc29_ = this.getMappedShipType(_loc29_);
               if(!Settings.createOpponents)
               {
                  break;
               }
               if(_loc19_ > 3)
               {
                  _loc19_ = 0;
               }
               if(_loc4_ == Hero.userID)
               {
                  break;
               }
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc31_ = _loc9_.getShipManager();
                  if(_loc31_ != null)
                  {
                     _loc30_ = _loc31_.createShip(_loc29_,_loc4_,_loc26_,_loc27_,1,_loc34_,_loc14_,_loc19_,_loc13_,_loc77_,_loc16_,_loc75_,_loc76_,_loc17_,_loc78_);
                     if(_loc30_ != null)
                     {
                        _loc30_.setCloak(_loc15_);
                     }
                     if(this._watchedShipInits[_loc4_])
                     {
                        this.main.getGroupManager().initMemberTarget(_loc4_);
                     }
                  }
               }
               else
               {
                  _loc11_ = new BufferedShip(_loc29_,_loc4_,_loc26_,_loc27_,1,_loc34_,_loc14_,_loc19_,_loc13_,_loc77_,_loc16_,_loc75_,_loc76_,_loc17_,_loc78_,_loc15_);
                  this.bufferedShips.push(_loc11_);
               }
               break;
            case ServerCommands.ROCKET_ATTACK:
               _loc7_ = int(_loc3_[2]);
               _loc8_ = int(_loc3_[3]);
               if(_loc3_[4] == "H")
               {
                  _loc79_ = true;
               }
               _loc80_ = int(_loc3_[5]);
               _loc81_ = int(_loc3_[6]);
               _loc82_ = Boolean(int(_loc3_[7]));
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getCombatManager().addRocketAttack(_loc7_,_loc8_,_loc80_,_loc79_,_loc81_,_loc82_);
               }
               break;
            case ServerCommands.TECHS:
               if(this.techAssembly == null)
               {
                  this.techAssembly = TechAssembly.getInstance();
               }
               this.techAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.SKILL_DESIGNS:
               if(this.skillsAssembly == null)
               {
                  this.skillsAssembly = SkillsAssembly.getInstance();
               }
               this.skillsAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.NEW_ASSET:
               if(this.assetAssembly == null)
               {
                  this.assetAssembly = AssetAssembly.getInstance();
               }
               this.assetAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.ASSET_INFO:
               _loc9_ = this.main.screenManager.map;
               _loc83_ = int(_loc3_[3]);
               _loc84_ = int(_loc3_[5]);
               _loc85_ = int(_loc3_[6]);
               _loc86_ = _loc9_.getStationManager().getAssetForID(_loc83_);
               _loc86_.toggleBorderClip(true);
               _loc86_.setDamageBarVisibility(true);
               _loc86_.updateHitpointBar(_loc84_,_loc85_);
               _loc87_ = _loc83_;
               if(_loc87_ == -1)
               {
                  if(_loc9_ != null)
                  {
                     _loc9_.getShipManager().deselectSelectedShip();
                  }
               }
               else
               {
                  _loc28_ = int(0);
                  _loc25_ = int(0);
                  _loc21_ = _loc84_;
                  _loc24_ = _loc85_;
                  _loc67_ = false;
                  if(_loc9_ != null)
                  {
                     _loc30_ = _loc9_.getShipManager().selectShip(_loc87_,_loc21_,_loc24_,_loc28_,_loc25_,_loc67_);
                     if(_loc30_ != null && !_loc30_.isNPC())
                     {
                        this.main.getGroupManager().prepareCandidate(_loc30_);
                     }
                  }
               }
               break;
            case ServerCommands.ASSET_HIT:
               _loc18_ = _loc3_[3];
               _loc21_ = int(_loc3_[4]);
               _loc28_ = int(_loc3_[5]);
               _loc20_ = int(_loc3_[6]);
               _loc4_ = int(_loc3_[7]);
               _loc64_ = int(_loc3_[8]);
               _loc9_ = this.main.screenManager.map;
               if(Settings.qualityExplosion == Settings.QUALITY_HIGH)
               {
                  if(_loc9_ != null)
                  {
                     _loc88_ = this.main.screenManager.map.getStationManager().getAssetForID(_loc4_);
                     if(_loc88_ != null)
                     {
                        _loc88_.updateHitpointBar(_loc21_,1000,true);
                     }
                  }
               }
               break;
            case ServerCommands.TARGET_IN_RANGE:
               this.main.getGuiManager().writeToLog(BPLocale.getText("fightcont"));
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getCombatManager().resumeLaserAttack(Hero.userID);
                  _loc9_.getCombatManager().resumeLaserAttackTo(Hero.userID);
               }
               break;
            case ServerCommands.ATTACK_INFO:
               _loc89_ = 1;
               _loc90_ = int(_loc3_[++_loc89_]);
               _loc91_ = int(_loc3_[++_loc89_]);
               _loc18_ = _loc3_[++_loc89_];
               _loc21_ = int(_loc3_[++_loc89_]);
               _loc28_ = Number(_loc3_[++_loc89_]);
               _loc20_ = int(_loc3_[++_loc89_]);
               _loc92_ = false;
               switch(_loc18_)
               {
                  case "H":
                     _loc64_ = 2;
                     _loc92_ = true;
                     break;
                  case "L":
                  case "R":
                  case "ECI":
                  case "SIN":
                  default:
                     _loc64_ = 0;
               }
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc30_ = _loc9_.getShipManager().getShip(_loc91_);
                  if(_loc30_ != null)
                  {
                     if(Settings.qualityExplosion == Settings.QUALITY_HIGH)
                     {
                        _loc30_.addShipDamage(_loc18_);
                     }
                     _loc30_.setHitpoints(_loc21_);
                     _loc30_.setShield(_loc28_);
                     _loc30_.updateHitpointShieldBar(true);
                     if(!_loc30_.shipPattern.isSpaceball() && Settings.displayHitpointBubbles && _loc20_ != 0)
                     {
                        this.main.getGuiManager().showHitpointDelta(_loc30_,_loc20_,_loc64_,_loc92_);
                     }
                  }
               }
               break;
            case ServerCommands.SHOOT_MISSED_A:
               _loc93_ = _loc3_[2];
               _loc4_ = int(_loc3_[3]);
               if(_loc3_[4] != undefined)
               {
                  _loc64_ = int(_loc3_[4]);
               }
               if(_loc93_ == "R")
               {
                  break;
               }
               if(Settings.displayHitpointBubbles)
               {
                  _loc9_ = this.main.screenManager.map;
                  if(_loc9_ != null)
                  {
                     _loc30_ = _loc9_.getShipManager().getShip(_loc4_);
                     if(_loc30_ != null && !_loc30_.shipPattern.isSpaceball())
                     {
                        this.main.getGuiManager().showHitpointDelta(_loc30_,0,_loc64_);
                     }
                  }
               }
               break;
            case ServerCommands.SET_MARKER:
               _loc94_ = new Sprite();
               _loc95_ = int(_loc3_[2]);
               _loc96_ = int(_loc3_[3]);
               _loc97_ = 40;
               _loc98_ = 4;
               _loc94_.graphics.beginFill(8453888);
               _loc94_.graphics.drawRect(_loc95_ - _loc97_ / 2,_loc96_ - _loc98_ / 2,_loc97_,_loc98_);
               _loc94_.graphics.drawRect(_loc95_ - _loc98_ / 2,_loc96_ - _loc97_ / 2,_loc98_,_loc97_);
               _loc94_.graphics.endFill();
               _loc99_ = new TextField();
               _loc99_.text = _loc95_ + "/" + _loc96_;
               _loc99_.textColor = 16711935;
               _loc99_.x = _loc95_ + 22;
               _loc99_.y = _loc96_ - 14;
               _loc94_.addChild(_loc99_);
               this.main.screenManager.getExplosionLayer().addChild(_loc94_);
               break;
            case ServerCommands.REMOVE_MARKERS:
               _loc100_ = this.main.screenManager.getExplosionLayer().numChildren;
               _loc145_ = 0;
               while(_loc145_ < _loc100_)
               {
                  this.main.screenManager.getExplosionLayer().removeChildAt(0);
                  _loc145_++;
               }
               break;
            case ServerCommands.SHOOT_MISSED_T:
               if(_loc3_[4] != undefined)
               {
                  _loc64_ = int(_loc3_[4]);
               }
               if(_loc93_ == "R")
               {
                  break;
               }
               if(Settings.displayHitpointBubbles)
               {
                  _loc9_ = this.main.screenManager.map;
                  if(_loc9_ != null)
                  {
                     _loc30_ = _loc9_.getShipManager().getHero();
                     if(_loc30_ != null && !_loc30_.shipPattern.isSpaceball())
                     {
                        this.main.getGuiManager().showHitpointDelta(_loc30_,0,_loc64_);
                     }
                  }
               }
               break;
            case ServerCommands.ATTACK_STOPPED_A:
               this.main.getGuiManager().writeToLog(BPLocale.getText("fightcanceled"));
               break;
            case ServerCommands.ATTACK_STOPPED_T:
               this.main.getGuiManager().writeToLog(BPLocale.getText("fightcanceledbyop"));
               break;
            case ServerCommands.HERO_INIT:
               _loc4_ = int(_loc3_[2]);
               _loc34_ = _loc3_[3];
               _loc32_ = int(_loc3_[4]);
               _loc33_ = int(_loc3_[5]) * 0.97;
               _loc28_ = int(_loc3_[6]);
               _loc25_ = int(_loc3_[7]);
               _loc21_ = int(_loc3_[8]);
               _loc24_ = int(_loc3_[9]);
               _loc12_ = int(_loc3_[10]);
               _loc23_ = int(_loc3_[11]);
               _loc35_ = int(_loc3_[12]);
               _loc36_ = int(_loc3_[13]);
               _loc22_ = int(_loc3_[14]);
               _loc19_ = int(_loc3_[15]);
               _loc13_ = int(_loc3_[16]);
               Hero.maxLaserCapacity = int(_loc3_[17]);
               Hero.maxRocketCapacity = int(_loc3_[18]);
               _loc101_ = int(_loc3_[19]);
               Hero.premium = Boolean(int(_loc3_[20]));
               Hero.experiencePoints = Number(_loc3_[21]);
               Hero.honorPoints = Number(_loc3_[22]);
               Hero.level = int(_loc3_[23]);
               Hero.creditsAmount = Number(_loc3_[24]);
               Hero.uridiumAmount = Number(_loc3_[25]);
               Hero.jackpotAmount = Number(_loc3_[26]);
               _loc16_ = int(_loc3_[27]);
               _loc14_ = _loc3_[28];
               _loc17_ = int(_loc3_[29]);
               _loc15_ = Boolean(int(_loc3_[31]));
               Hero.isKilled = false;
               this.main.getGuiManager().removeStopoverView();
               _loc32_ = this.getMappedShipType(_loc32_);
               if(_loc16_ == 21)
               {
                  Hero.admin = true;
               }
               else
               {
                  Hero.admin = false;
               }
               Hero.username = _loc34_;
               if(StringUtil.trim(_loc14_).length > 0)
               {
                  Hero.clan = _loc14_;
               }
               Hero.factionID = _loc19_;
               if(Settings.lastMapID != -1 && Settings.lastMapID != _loc22_)
               {
                  AudioManager.playSoundEffect(6);
               }
               if(Settings.lastMapID != _loc22_)
               {
                  this.isMapLoaded = false;
                  this.main.createMap(_loc22_);
                  Settings.lastMapID = _loc22_;
               }
               _loc10_ = this.main.screenManager.map.getShipManager().createShip(_loc32_,_loc4_,_loc35_,_loc36_,_loc33_,_loc34_,_loc14_,_loc19_,_loc13_,-1,_loc16_,_loc101_,false,_loc17_,false);
               if(_loc32_ == 80)
               {
                  _loc10_.isCubicon = true;
               }
               if(_loc10_ == null)
               {
                  return;
               }
               _loc10_.setHitpoints(_loc21_);
               _loc10_.setMaxHitpoints(_loc24_);
               _loc10_.setCargo(_loc23_ - _loc12_);
               _loc10_.setMaxCargo(_loc23_);
               _loc10_.setShieldChunk(_loc28_,_loc25_,true);
               if(Settings.createOpponents)
               {
                  _loc9_ = this.main.screenManager.map;
                  _loc31_ = _loc9_.getShipManager();
                  _loc59_ = 0;
                  while(_loc59_ < this.bufferedShips.length)
                  {
                     _loc11_ = this.bufferedShips[_loc59_];
                     if(_loc19_ > 3)
                     {
                        _loc19_ = 0;
                     }
                     if(_loc31_ != null)
                     {
                        _loc30_ = _loc31_.createShip(_loc11_.typeID,_loc11_.userID,_loc11_.xPos,_loc11_.yPos,1,_loc11_.username,_loc11_.clanTag,_loc11_.fractionID,_loc11_.clanID,_loc11_.clanDiplomacy,_loc11_.dailyRank,_loc11_.expansionstage,_loc11_.warnIconOnMap,_loc11_.galaxyGatesFinished,_loc11_.isNPC);
                        _loc30_.setCloak(_loc11_.cloaked);
                     }
                     _loc59_++;
                  }
                  this.bufferedShips = [];
               }
               this.main.getGuiManager().removeConnectionWindow();
               this.main.screenManager.map.getEventManager().unlockControls();
               this.main.getGuiManager().loadChat();
               this.main.getGuiManager().createLogWindow();
               this.main.getGuiManager().addGUI();
               _loc102_ = this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_JACKPOTBATTLE);
               if(_loc102_ != null)
               {
                  this.main.getGuiManager().closeWindow(this.main.getGuiManager().getWindow(SimpleWindow.WINDOW_CLASS_JACKPOTBATTLE));
               }
               this.main.getGuiManager().createWindow(SimpleWindow.WINDOW_CLASS_USER);
               this.main.getGuiManager().createWindow(SimpleWindow.WINDOW_CLASS_SHIP);
               this.main.getGuiManager().createQuestWindow();
               if(Settings.showInstantLog)
               {
                  this.main.getGuiManager().createInstantLogView();
               }
               this.main.getGuiManager().createGlobalNotificationView();
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_LASER);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_ROCKETS);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_CREDITS);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_URIDIUM);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_3,SimpleElement.TYPE_JACKPOT);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_EXPERIENCE);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_HONOR);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_LEVEL);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_USER,SimpleContainer.CONTAINER_CLASS_HERO_INFO_2,SimpleElement.TYPE_JUMP_VOUCHERS);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_0,SimpleElement.TYPE_HITPOINTS);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_0,SimpleElement.TYPE_SHIELD);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_0,SimpleElement.TYPE_CARGO);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_LASER);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_ROCKETS);
               this.main.setScheduledDisconnect(false);
               if(Hero.admin)
               {
                  this.main.getGuiManager().createCommandLineInterface();
               }
               this.main.getGuiManager().unlockWindow(SimpleWindow.WINDOW_CLASS_LOGOUT);
               this.main.getGroupManager().init();
               this.main.getGuiManager().destroyWindow(SimpleWindow.WINDOW_CLASS_TDM);
               this.main.getTDMManager().cleanUp();
               if(Main.showCross)
               {
                  this.main.getGuiManager().showCrosshair();
                  this.main.getGuiManager().moveCrosshairs(_loc35_,_loc36_);
               }
               _loc10_.setCloak(_loc15_);
               this.isHeroLoaded = true;
               this.dispatchSpacemapLoaded();
               break;
            case ServerCommands.BEACON:
               _loc5_ = int(_loc3_[2]);
               _loc6_ = int(_loc3_[3]);
               _loc103_ = Boolean(int(_loc3_[4]));
               _loc104_ = Boolean(int(_loc3_[5]));
               _loc105_ = Boolean(int(_loc3_[6]));
               _loc106_ = Boolean(int(_loc3_[7]));
               _loc107_ = Boolean(int(_loc3_[8]));
               _loc108_ = int(_loc3_[9]);
               Hero.setDemilitarizedZone(_loc103_,this.main);
               Hero.setInTradeArea(_loc105_,this.main);
               Hero.setInJumpArea(_loc107_);
               _loc66_ = this.main.getGuiManager();
               if(_loc66_ != null)
               {
                  _loc146_ = _loc66_.getWindow(SimpleWindow.WINDOW_CLASS_LOGOUT);
                  if(_loc146_ != null && _loc146_.isMaximizeClicked())
                  {
                     return;
                  }
               }
               Settings.fastRepair = _loc108_;
               if(_loc66_ != null)
               {
                  _loc147_ = _loc66_.getTopMenu();
                  if(_loc147_ != null)
                  {
                     if(_loc108_ > 0)
                     {
                        _loc147_.setButtonAccess(SuperActionButton.ACTION_FASTREPAIR,true);
                        _loc109_ = _loc147_.getButton(SuperActionButton.ACTION_FASTREPAIR);
                        _loc109_.setCounterVisibility(true);
                        _loc109_.setCount(_loc108_);
                     }
                     else
                     {
                        _loc147_.setButtonAccess(SuperActionButton.ACTION_FASTREPAIR,false);
                        _loc109_ = _loc147_.getButton(SuperActionButton.ACTION_FASTREPAIR);
                        _loc109_.setCounterVisibility(false);
                     }
                  }
               }
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc31_ = _loc9_.getShipManager();
                  _loc10_ = _loc31_.getHero();
                  if(_loc10_ != null)
                  {
                     this.main.getGuiManager().showRadiationWarning(_loc106_);
                     if(Main.showCross)
                     {
                        this.main.getGuiManager().moveCrosshairs(_loc5_,_loc6_);
                     }
                     if(_loc104_ && Hero.repairSkillId != -1)
                     {
                        _loc148_ = PatternManager.robotPatterns[Hero.repairSkillId];
                        if(!this.effectsManager.doesEffectExistOn(_loc10_,EffectIDList.TECH_BATTLE_REP_BOT_EFFECT))
                        {
                           _loc149_ = new BattleRepBotTechEffect(EffectIDList.TECH_BATTLE_REP_BOT_EFFECT,new EffectPattern(EffectIDList.TECH_BATTLE_REP_BOT_EFFECT,_loc148_.resKey));
                           this.effectsManager.addEffect(_loc149_,_loc10_,EffectsManager.NORMAL_EFFECT);
                        }
                     }
                     else
                     {
                        this.effectsManager.removeEffectByIdFromEntity(_loc10_,EffectIDList.TECH_BATTLE_REP_BOT_EFFECT);
                     }
                  }
               }
               break;
            case ServerCommands.SHIP_SELECTED:
               _loc110_ = int(_loc3_[2]);
               _loc9_ = this.main.screenManager.map;
               _loc111_ = _loc9_.getStationManager().assets;
               _loc59_ = 0;
               while(_loc59_ < _loc111_.length)
               {
                  _loc111_[_loc59_].toggleBorderClip(false);
                  _loc111_[_loc59_].setDamageBarVisibility(false);
                  _loc59_++;
               }
               if(_loc110_ == -1)
               {
                  if(_loc9_ != null)
                  {
                     _loc9_.getShipManager().deselectSelectedShip();
                  }
               }
               else
               {
                  _loc28_ = int(_loc3_[4]);
                  _loc25_ = int(_loc3_[5]);
                  _loc21_ = int(_loc3_[6]);
                  _loc24_ = int(_loc3_[7]);
                  _loc67_ = Boolean(int(_loc3_[8]));
                  if(_loc9_ != null)
                  {
                     _loc30_ = _loc9_.getShipManager().selectShip(_loc110_,_loc21_,_loc24_,_loc28_,_loc25_,_loc67_);
                     if(_loc67_)
                     {
                        _loc30_.showShield(0);
                     }
                     if(!_loc30_.isNPC())
                     {
                        this.main.getGroupManager().prepareCandidate(_loc30_);
                     }
                  }
               }
               break;
            case ServerCommands.DESTROY_SHIP:
               _loc4_ = int(_loc3_[2]);
               _loc112_ = -1;
               if(_loc4_ != Hero.userID)
               {
                  _loc9_ = this.main.screenManager.map;
                  if(_loc9_ != null)
                  {
                     if(_loc3_.length > 3)
                     {
                        _loc112_ = int(_loc3_[3]);
                        _loc30_ = _loc9_.getShipManager().getShip(_loc4_);
                        if(_loc30_ != null)
                        {
                           _loc30_.explodeTypeID = _loc112_;
                        }
                     }
                     this.main.screenManager.map.getShipManager().removeOpponentShip(_loc4_,true);
                  }
               }
               else
               {
                  Hero.isKilled = true;
                  this.main.screenManager.map.getShipManager().destroyHero();
               }
               break;
            case ServerCommands.REMOVE_SHIP:
               _loc4_ = int(_loc3_[2]);
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getShipManager().removeOpponentShip(_loc4_);
               }
               break;
            case ServerCommands.REMOVE_BOX:
               _loc38_ = _loc3_[2];
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getCollectableManager().removeCollectable(_loc38_);
               }
               break;
            case ServerCommands.PLAY_PORTAL_ANIMATION:
               this.main.setScheduledDisconnect(true);
               _loc39_ = int(_loc3_[2]);
               _loc40_ = int(_loc3_[3]);
               Settings.nextMapID = _loc39_;
               AudioManager.playSoundEffect(21);
               this.main.getGuiManager().lockWindow(SimpleWindow.WINDOW_CLASS_LOGOUT);
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null && _loc9_.getMapID() != _loc39_)
               {
                  _loc9_.portalManager.playPortalAnimation(_loc40_);
                  _loc9_.getDroneManager().minimizeDrones();
               }
               break;
            case ClientCommands.SELECT:
               _loc41_ = _loc3_[2];
               switch(_loc41_)
               {
                  case ClientCommands.CONFIGURATION:
                     _loc54_ = int(_loc3_[3]);
                     Settings.selectedConfiguration = _loc54_;
                     this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_CONFIGURATION);
                     this.main.getGuiManager().updateSpacemapWindow();
               }
               break;
            case ServerCommands.PORTAL_JUMP:
               this.main.setScheduledDisconnect(true);
               Settings.nextMapID = int(_loc3_[2]);
               break;
            case ServerCommands.PRIMARY_WEAPON_INFO:
               _loc113_ = 0;
               _loc59_ = 2;
               while(_loc59_ < _loc3_.length)
               {
                  var _loc176_:Number;
                  Hero.laserBatteryAmounts[_loc176_ = _loc113_++] = int(_loc3_[_loc59_]);
                  _loc59_++;
               }
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_LASER);
               this.main.getGuiManager().getMenuManager().updateLaserButtonAmounts();
               break;
            case ServerCommands.SECONDARY_WEAPON_INFO:
               _loc89_ = 1;
               Hero.rocketAmounts[RocketPattern.R310] = int(_loc3_[++_loc89_]);
               Hero.rocketAmounts[RocketPattern.PLT_2026] = int(_loc3_[++_loc89_]);
               Hero.rocketAmounts[RocketPattern.PLT_2021] = int(_loc3_[++_loc89_]);
               Hero.rocketAmounts[RocketPattern.PLT_3030] = int(_loc3_[++_loc89_]);
               Hero.rocketAmounts[RocketPattern.PLD_8] = int(_loc3_[++_loc89_]);
               Hero.rocketAmounts[RocketPattern.DCR_250] = int(_loc3_[++_loc89_]);
               Hero.rocketAmounts[RocketPattern.WIZ] = int(_loc3_[++_loc89_]);
               Hero.explosiveAmounts[SpecialAmmunition.MINE] = int(_loc3_[++_loc89_]);
               Hero.explosiveAmounts[SpecialAmmunition.SMARTBOMB] = int(_loc3_[++_loc89_]);
               Hero.explosiveAmounts[SpecialAmmunition.INSTASHIELD] = int(_loc3_[++_loc89_]);
               Hero.explosiveAmounts[SpecialAmmunition.EMP] = int(_loc3_[++_loc89_]);
               Hero.explosiveAmounts[SpecialAmmunition.MINE_EMP] = int(_loc3_[++_loc89_]);
               Hero.explosiveAmounts[SpecialAmmunition.MINE_SAB] = int(_loc3_[++_loc89_]);
               Hero.explosiveAmounts[SpecialAmmunition.MINE_DDM] = int(_loc3_[++_loc89_]);
               this.main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_ROCKETS);
               this.main.getGuiManager().getMenuManager().updateRocketButtonAmounts();
               this.main.getGuiManager().getMenuManager().updateExplosiveButtonAmmounts();
               break;
            case ServerCommands.BOX_COLLECT_RESPONSE:
            case ServerCommands.LOG_MESSAGE:
               this.boxCollectAssembly.assembleBoxCollectResponse(_loc3_);
               break;
            case ServerCommands.SET_ATTRIBUTE:
               this.attributesAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.ACHIEVEMENTS:
               switch(_loc3_[2])
               {
                  case ServerCommands.ACHIEVEMENT_SET:
                     _loc59_ = 3;
                     while(_loc59_ < _loc3_.length - 2)
                     {
                        _loc150_ = int(_loc3_[_loc59_]);
                        _loc151_ = Boolean(int(_loc3_[_loc59_ + 1]));
                        _loc152_ = int(_loc3_[_loc59_ + 2]);
                        this.main.achievementManager.setAchievement(_loc150_,_loc151_,_loc152_);
                        _loc59_ += 3;
                     }
                     break;
                  case ServerCommands.ACHIEVEMENT_REMOVE:
                     _loc59_ = 3;
                     while(_loc59_ < _loc3_.length)
                     {
                        _loc150_ = int(_loc3_[_loc59_]);
                        this.main.achievementManager.removeAchievement(_loc150_);
                        _loc59_++;
                     }
                     break;
                  case ServerCommands.ACHIEVEMENT_END:
                     this.main.achievementManager.removeAchievementWindow();
               }
               break;
            case ServerCommands.GROUPSYSTEM:
               this.groupSystemAssembly.assembleGroupSystemEvent(_loc3_);
               break;
            case ServerCommands.QUESTFM_INFO:
               this.questAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.OUT_OF_RANGE:
               this.main.getGuiManager().writeToLog(BPLocale.getText("outofrange"));
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getCombatManager().idleLaserAttack(Hero.userID,true);
                  _loc9_.getCombatManager().idleLaserAttackTo(Hero.userID);
               }
               break;
            case ServerCommands.ESCAPE:
               this.main.getGuiManager().writeToLog(BPLocale.getText("attescape"));
               break;
            case ServerCommands.IN_NO_ATTACK_ZONE:
               this.main.getGuiManager().writeToLog(BPLocale.getText("peacearea"));
               break;
            case ServerCommands.NO_AMMUNITION:
               _loc44_ = _loc3_[2];
               _loc114_ = int(_loc3_[4]);
               this.main.getGuiManager().noAmmunition(_loc44_,_loc114_);
               break;
            case ServerCommands.AUTO_AMMUNITION_CHANGE:
               _loc44_ = _loc3_[2];
               _loc115_ = int(_loc3_[4]);
               this.main.getGuiManager().getMenuManager().autoAmmunitionChange(_loc44_,_loc115_);
               break;
            case ServerCommands.NEW_MAP:
               break;
            case ServerCommands.SET_MAP_PVP_STATUS:
               _loc116_ = int(_loc3_[2]);
               _loc117_ = int(_loc3_[3]);
               _loc9_ = this.main.screenManager.map;
               _loc9_.setPvpAllowed(_loc116_);
               _loc9_.setHomeMapFaction(_loc117_);
               break;
            case ServerCommands.POI:
               if(this.poiAssembly == null)
               {
                  this.poiAssembly = POIAssembly.getInstance();
               }
               this.poiAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.CREATE_STATION:
               _loc45_ = int(_loc3_[3]);
               _loc118_ = int(_loc3_[2]);
               _loc119_ = _loc3_[4];
               _loc19_ = int(_loc3_[5]);
               _loc26_ = int(_loc3_[7]);
               _loc27_ = int(_loc3_[8]);
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null && Settings.qualityBackground >= Settings.QUALITY_LOW)
               {
                  this.main.screenManager.map.getStationManager().addSpaceStation(_loc118_,_loc19_,_loc119_,_loc26_,_loc27_);
               }
               break;
            case ServerCommands.CHANGE_HEALTH_STATION_STATUS:
               _loc9_ = this.main.screenManager.map;
               _loc120_ = _loc9_.getStationManager().getStations();
               _loc121_ = Boolean(int(_loc3_[2]));
               _loc59_ = 0;
               while(_loc59_ < _loc120_.length)
               {
                  if(_loc120_[_loc59_] != undefined)
                  {
                     _loc122_ = _loc120_[_loc59_] as Station;
                     if(_loc122_.getTypeID() == 4)
                     {
                        _loc122_.setHealthStationStatus(_loc121_);
                     }
                  }
                  _loc59_++;
               }
               break;
            case ServerCommands.CREATE_PORTAL:
               _loc125_ = true;
               _loc126_ = new Vector.<int>();
               if(_loc3_.length < 9)
               {
                  _loc123_ = int(_loc3_[2]);
                  _loc45_ = int(_loc3_[3]);
                  _loc26_ = int(_loc3_[5]);
                  _loc27_ = int(_loc3_[6]);
               }
               else
               {
                  _loc123_ = int(_loc3_[2]);
                  _loc124_ = int(_loc3_[3]);
                  _loc45_ = int(_loc3_[4]);
                  _loc26_ = int(_loc3_[5]);
                  _loc27_ = int(_loc3_[6]);
                  _loc125_ = Boolean(int(_loc3_[7]));
                  _loc153_ = String(_loc3_[8]);
                  _loc154_ = _loc153_.split(LIST_SEPERATOR);
                  for each(_loc155_ in _loc154_)
                  {
                     if(_loc155_ > 0)
                     {
                        _loc126_.push(_loc155_);
                     }
                  }
               }
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null && Settings.createPortals)
               {
                  this.main.screenManager.map.portalManager.createPortal(_loc123_,_loc124_,_loc45_,_loc26_,_loc27_,_loc125_,_loc126_);
               }
               break;
            case ServerCommands.CREATE_MINE:
               _loc38_ = _loc3_[2];
               _loc45_ = int(_loc3_[3]);
               _loc26_ = int(_loc3_[4]);
               _loc27_ = int(_loc3_[5]);
               _loc127_ = int(_loc3_[6]);
               _loc128_ = int(_loc3_[7]);
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  if(_loc45_ >= 100 && _loc45_ <= 533)
                  {
                     _loc9_.getCollectableManager().createCollectable(CollectablePattern.TYPE_FIREWORKS_BOX,_loc38_,_loc45_,_loc26_,_loc27_);
                  }
                  else
                  {
                     _loc9_.getMineManager().createMine(_loc38_,_loc45_,_loc26_,_loc27_,_loc127_,_loc128_);
                  }
               }
               break;
            case ServerCommands.CREATE_ORE:
               _loc38_ = _loc3_[2];
               _loc45_ = int(_loc3_[3]);
               _loc26_ = int(_loc3_[4]);
               _loc27_ = int(_loc3_[5]);
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  if(_loc45_ < 10 || _loc45_ == 15)
                  {
                     if(!Settings.createCollectables)
                     {
                        break;
                     }
                     _loc9_.getCollectableManager().createCollectable(CollectablePattern.TYPE_ORE,_loc38_,_loc45_,_loc26_,_loc27_);
                  }
                  else if(_loc45_ == 10)
                  {
                     _loc9_.getMineManager().createMine(_loc38_,_loc45_,_loc26_,_loc27_);
                  }
                  else if(_loc45_ >= 100 && _loc45_ <= 533)
                  {
                     _loc9_.getCollectableManager().createCollectable(CollectablePattern.TYPE_FIREWORKS_BOX,_loc38_,_loc45_,_loc26_,_loc27_);
                  }
               }
               break;
            case ServerCommands.ORE_COLLECTED_BY_HERO:
               _loc129_ = int(_loc3_[2]);
               if(_loc3_.length > 3)
               {
                  _loc156_ = this.main.screenManager.map.getShipManager().getHero().pet;
                  _loc157_ = PatternManager.getCollectablePattern(CollectablePattern.TYPE_BOX,CollectablePattern.TYPE_BOX);
                  _loc158_ = _loc156_.x;
                  _loc159_ = _loc156_.y + _loc156_.getClipContainer().height * 0.5;
                  this.main.screenManager.map.getCollectableManager().showBeam(_loc158_,_loc159_,1000,"beam0");
                  _loc160_ = _loc157_.getSoundID();
                  if(_loc160_ != -1)
                  {
                     AudioManager.playSoundEffect(_loc160_,false,false,_loc156_.x,_loc156_.y);
                  }
               }
               if(_loc129_ != 666)
               {
                  _loc161_ = BPLocale.getText("oksammel");
                  _loc161_ = _loc161_.replace(/%!/,InGameCatalog.instance.ore_names[_loc129_]);
                  this.main.getGuiManager().writeToLog(_loc161_);
               }
               break;
            case ServerCommands.CARGO_FULL:
               this.main.getGuiManager().writeToLog(BPLocale.getText("loadfull"));
               if(Settings.JS_EVENT_TRACKING_ENABLED)
               {
                  if(ExternalInterface.available)
                  {
                     ExternalInterface.call("clientEvent","cargoFull");
                  }
               }
               break;
            case ServerCommands.BOX_DISABLED:
               this.main.getGuiManager().writeToLog(BPLocale.getText("boxdisabled"));
               break;
            case ServerCommands.REMOVE_ORE:
               _loc38_ = _loc3_[2];
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  if(!this.main.screenManager.map.getMineManager().removeMine(_loc38_))
                  {
                     this.main.screenManager.map.getCollectableManager().removeCollectable(_loc38_);
                  }
               }
               break;
            case ServerCommands.CREATE_BOX:
               _loc38_ = _loc3_[2];
               _loc45_ = int(_loc3_[3]);
               _loc26_ = int(_loc3_[4]);
               _loc27_ = int(_loc3_[5]);
               if(!Settings.createCollectables)
               {
                  break;
               }
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  if(_loc45_ > CollectablePattern.BEACON_FRONTIER_ID)
                  {
                     _loc9_.getCollectableManager().createCollectable(CollectablePattern.TYPE_BEACON,_loc38_,_loc45_,_loc26_,_loc27_);
                  }
                  else if(_loc3_[6] != undefined)
                  {
                     _loc9_.getCollectableManager().createCollectable(CollectablePattern.TYPE_BOX,_loc38_,_loc45_,_loc26_,_loc27_,int(_loc3_[6]));
                  }
                  else
                  {
                     _loc9_.getCollectableManager().createCollectable(CollectablePattern.TYPE_BOX,_loc38_,_loc45_,_loc26_,_loc27_);
                  }
               }
               break;
            case ServerCommands.MAP_EVENT:
               if(this.mapEventsAssembly == null)
               {
                  this.mapEventsAssembly = MapEventsAssembly.getInstance();
               }
               this.mapEventsAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.LOGOUT:
               _loc130_ = this.main.getGuiManager().getGlobalchat();
               if(_loc130_ != null)
               {
                  _loc130_.cleanup();
               }
               this.main.setScheduledDisconnect(true);
               if(ExternalInterface.available)
               {
                  ExternalInterface.call("bpCloseWindow","");
               }
               else
               {
                  System.exit(0);
               }
               break;
            case ServerCommands.LOGOUT_CANCEL_FROM_SERVER:
               this.main.getGuiManager().logoutCancelFromServer();
               break;
            case ServerCommands.SET_PRICES:
               switch(_loc3_[2])
               {
                  case ServerCommands.SET_AMMO_PRICES:
                     _loc59_ = 3;
                     while(_loc59_ < _loc3_.length)
                     {
                        _loc162_ = _loc3_[_loc59_];
                        _loc163_ = _loc162_.split(",");
                        _loc50_ = StringUtil.trim(_loc163_.shift());
                        _loc51_ = _loc163_.shift();
                        _loc164_ = 0;
                        _loc165_ = 0;
                        while(_loc165_ < _loc163_.length / 3)
                        {
                           _loc166_ = int(_loc163_[_loc164_]);
                           _loc167_ = int(_loc163_[_loc164_ + 1]);
                           _loc52_ = _loc163_[_loc164_ + 2];
                           if(_loc50_ == "b")
                           {
                              _loc168_ = new AmmoPrice(AmmoPrice.CATEGORY_LASER,_loc51_,_loc166_,_loc167_,_loc52_);
                           }
                           else if(_loc50_ == "r")
                           {
                              _loc168_ = new AmmoPrice(AmmoPrice.CATEGORY_ROCKET,_loc51_,_loc166_,_loc167_,_loc52_);
                           }
                           PatternManager.ammoPrices.push(_loc168_);
                           _loc164_ += 3;
                           _loc165_++;
                        }
                        _loc59_++;
                     }
                     this.main.getGuiManager().getMenuManager().updateAmmoPrices();
                     break;
                  default:
                     OrePattern(PatternManager.orePatterns[OrePattern.ORE_PROMETIUM]).price = int(_loc3_[2]);
                     OrePattern(PatternManager.orePatterns[OrePattern.ORE_ENDURIUM]).price = int(_loc3_[3]);
                     OrePattern(PatternManager.orePatterns[OrePattern.ORE_TERBIUM]).price = int(_loc3_[4]);
                     OrePattern(PatternManager.orePatterns[OrePattern.ORE_PROMETID]).price = int(_loc3_[5]);
                     OrePattern(PatternManager.orePatterns[OrePattern.ORE_DURANIUM]).price = int(_loc3_[6]);
                     OrePattern(PatternManager.orePatterns[OrePattern.ORE_PROMERIUM]).price = int(_loc3_[7]);
                     OrePattern(PatternManager.orePatterns[OrePattern.ORE_PALLADIUM]).price = int(_loc3_[8]);
                     this.main.getGuiManager().updateTradeWindow();
                     this.main.getGuiManager().showTradeWindow();
               }
               break;
            case ServerCommands.SET_ORE_COUNT:
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_PROMETIUM]).count = int(_loc3_[2]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_ENDURIUM]).count = int(_loc3_[3]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_TERBIUM]).count = int(_loc3_[4]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_XENOMIT]).count = int(_loc3_[5]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_PROMETID]).count = int(_loc3_[6]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_DURANIUM]).count = int(_loc3_[7]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_PROMERIUM]).count = int(_loc3_[8]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_SEPROM]).count = int(_loc3_[9]);
               OrePattern(PatternManager.orePatterns[OrePattern.ORE_PALLADIUM]).count = int(_loc3_[10]);
               this.main.getGuiManager().updateTradeWindow();
               this.main.getGuiManager().updateRefinementWindow();
               _loc9_ = this.main.screenManager.map;
               if(_loc9_ != null)
               {
                  _loc9_.getShipManager().updateHeroCargo();
               }
               break;
            case ServerCommands.BUY:
               switch(_loc3_[2])
               {
                  case ServerCommands.BUY_SUCCESS:
                     _loc50_ = _loc3_[3];
                     _loc169_ = int(_loc3_[4]);
                     _loc51_ = int(_loc3_[5]);
                     if(_loc50_ == "b")
                     {
                        this.main.getGuiManager().writeToLog(BPLocale.getText("bought_bat").replace("%TYPE%",_loc169_).replace("%COUNT%",BPLocale.roundInteger(_loc51_)));
                     }
                     else if(_loc50_ == "r")
                     {
                        this.main.getGuiManager().writeToLog(BPLocale.getText("bought_rok").replace("%TYPE%",_loc169_).replace("%COUNT%",BPLocale.roundInteger(_loc51_)));
                     }
                     break;
                  case ServerCommands.BUY_FAILED:
                     switch(_loc3_[3])
                     {
                        case ServerCommands.BUY_FAILED_NO_MONEY:
                           _loc52_ = _loc3_[4];
                           if(_loc52_ == "U")
                           {
                              this.main.getGuiManager().writeToLog(BPLocale.getText("ammobuy_fail_uri"));
                           }
                           else if(_loc52_ == "C")
                           {
                              this.main.getGuiManager().writeToLog(BPLocale.getText("ammobuy_fail_cre"));
                           }
                           break;
                        case ServerCommands.BUY_FAILED_NO_CARGO:
                           this.main.getGuiManager().writeToLog(BPLocale.getText("ammobuy_fail_space"));
                     }
               }
               break;
            case ServerCommands.CLIENT_SETTING:
               this.settingsAssembly.assembleSetting(_loc3_.splice(2));
               break;
            case ServerCommands.JUMP_FAILED:
               _loc65_ = BPLocale.getText("jumplevelfalse").replace(/%!/,_loc3_[2]);
               this.main.getGuiManager().writeToLog(_loc65_);
               AudioManager.playSoundEffect(29);
               break;
            case ServerCommands.LAB:
               switch(_loc3_[2])
               {
                  case ServerCommands.UPDATE:
                     switch(_loc3_[3])
                     {
                        case ServerCommands.INFO:
                           _loc59_ = 4;
                           while(_loc59_ < _loc3_.length)
                           {
                              _loc170_ = _loc3_[_loc59_];
                              _loc171_ = int(_loc3_[_loc59_ + 1]);
                              _loc172_ = int(_loc3_[_loc59_ + 2]);
                              _loc59_ += 2;
                              this.main.getGuiManager().refinementManager.updateItem(_loc170_,_loc171_,_loc172_);
                              _loc59_++;
                           }
                           break;
                        case ServerCommands.GET:
                     }
               }
               break;
            case ServerCommands.USER_INTERFACE:
               this.uiAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.ROCKETLAUNCHER:
               this.rocketLauncherAssembly.assembleCommand(_loc3_);
               break;
            case ServerCommands.SPECIAL_ENEMY:
               switch(_loc3_[2])
               {
                  case ServerCommands.ALIENMOTHERSHIP:
                     _loc9_ = this.main.screenManager.map;
                     _loc123_ = int(_loc3_[4]);
                     _loc173_ = int(_loc3_[5]);
                     switch(_loc3_[3])
                     {
                        case ServerCommands.MOVE:
                           if(_loc9_ != null)
                           {
                              _loc60_ = int(_loc3_[5]);
                              _loc61_ = int(_loc3_[6]);
                              _loc174_ = int(_loc3_[7]);
                              _loc9_.alienMothershipManager.move(_loc123_,_loc60_,_loc61_,_loc174_);
                           }
                           break;
                        case ServerCommands.CREATE:
                           _loc60_ = int(_loc3_[5]);
                           _loc61_ = int(_loc3_[6]);
                           if(_loc9_ != null)
                           {
                              _loc9_.alienMothershipManager.createAlienMothership(_loc123_,_loc60_,_loc61_);
                           }
                           break;
                        case ServerCommands.ROTATE:
                           if(_loc9_ != null)
                           {
                              _loc9_.alienMothershipManager.rotateAlienMothership(_loc123_,_loc173_);
                           }
                           break;
                        case ServerCommands.PREPARE_ATTACK:
                           if(_loc9_ != null)
                           {
                              _loc9_.alienMothershipManager.prepareAttack(_loc123_,_loc173_);
                           }
                           break;
                        case ServerCommands.PREPARE_BIG_ATTACK:
                           if(_loc9_ != null)
                           {
                              _loc9_.alienMothershipManager.prepareBigAttack(_loc123_,_loc173_);
                           }
                           break;
                        case ServerCommands.CLOAK:
                           if(_loc9_ != null)
                           {
                              _loc9_.alienMothershipManager.cloak(_loc123_,_loc173_);
                           }
                           break;
                        case ServerCommands.IDLE:
                           if(_loc9_ != null)
                           {
                              _loc9_.alienMothershipManager.idle(_loc123_);
                           }
                           break;
                        case ServerCommands.KILL:
                           if(_loc9_ != null)
                           {
                              _loc9_.alienMothershipManager.kill(_loc123_);
                           }
                     }
               }
               break;
            case ServerCommands.TRACKING:
               _loc131_ = Capabilities.version;
               _loc132_ = int(this.main.getGuiManager().debugView.currentFPS);
               _loc133_ = int(this.main.getGuiManager().debugView.currentMem);
               _loc134_ = int(this.main.getGuiManager().debugView.averageFPS);
               _loc135_ = int(this.main.getGuiManager().debugView.minFPS);
               _loc136_ = int(this.main.getGuiManager().debugView.maxFPS);
               _loc137_ = int(this.main.getGuiManager().debugView.averageMem);
               _loc138_ = int(this.main.getGuiManager().debugView.minMem);
               _loc139_ = int(this.main.getGuiManager().debugView.maxMem);
               this.main.getGuiManager().debugView.refreshTracking();
               this.sendCommand(ServerCommands.TRACKING,[_loc131_,_loc132_,_loc133_,_loc134_,_loc135_,_loc136_,_loc137_,_loc138_,_loc139_]);
               break;
            case ServerCommands.CHANGE_MAP:
               this.isHeroLoaded = false;
         }
         switch(_loc3_[0])
         {
            case ServerCommands.ERROR:
               _loc175_ = uint(int(_loc3_[1]));
               switch(_loc175_)
               {
                  case ServerCommands.NO_HITPOINTS:
                     Hero.isKilled = true;
                     if(this.xmlSocket.connected)
                     {
                        this.main.setScheduledDisconnect(true);
                        this.xmlSocket.close();
                     }
                     this.main.getGuiManager().removeConnectionWindow();
                     TweenMax.delayedCall(2,this.main.getGuiManager().showHeroDestroyedWindow);
                     break;
                  case ServerCommands.NOT_LOGGED_IN:
                     this.main.setScheduledDisconnect(true);
                     this.main.getGuiManager().removeConnectionWindow();
                     this.main.screenManager.showSimpleMessage(BPLocale.getText("notloggedin"));
                     break;
                  case ServerCommands.DOUBLE_LOGGED_IN:
                     this.main.setScheduledDisconnect(true);
                     this.main.getGuiManager().removeConnectionWindow();
                     this.main.screenManager.showSimpleMessage(BPLocale.getText("doubleloggedin"));
                     break;
                  case ServerCommands.INVALID_SESSION:
               }
               break;
            case ServerCommands.KICKED:
         }
      }
      
      public function getMappedShipType(param1:int) : int
      {
         var _loc2_:Array = [171,71,173,73,175,75,176,76,177,77,178,78,179,79,181,81,183,83];
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            if(param1 == _loc2_[_loc3_])
            {
               return _loc2_[_loc3_ + 1];
            }
            _loc3_ += 2;
         }
         return param1;
      }
      
      public function get isLoggingGameServerIO() : Boolean
      {
         return this._isLoggingGameServerIO;
      }
      
      public function set isLoggingGameServerIO(param1:Boolean) : void
      {
         this._isLoggingGameServerIO = param1;
         if(this._isLoggingGameServerIO)
         {
            this.ioLogger = CommandLog.instance;
         }
      }
   }
}

