package net.bigpoint.darkorbit.net
{
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.settings.Settings;
   import net.bigpoint.darkorbit.ship.BufferedShip;
   import net.bigpoint.darkorbit.ship.Ship;
   import net.bigpoint.darkorbit.ship.ShipManager;
   import net.bigpoint.darkorbit.station.RelayStation;
   import net.bigpoint.darkorbit.station.Station;
   
   public class AssetAssembly extends BaseAssembly
   {
      
      private static var _instance:AssetAssembly;
      
      private var map:Map;
      
      private var delegateDict:Dictionary;
      
      private var main:Main;
      
      public function AssetAssembly(param1:Function)
      {
         super();
         if(param1 != hidden)
         {
            throw new Error("AssetAssembly is a Singleton and can only be accessed through AssetAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : AssetAssembly
      {
         if(_instance == null)
         {
            _instance = new AssetAssembly(hidden);
         }
         return _instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.CREATE_ASSET] = this.assembleCreateAssetCommand;
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      public function assembleCreateAssetCommand(param1:Array) : void
      {
         var _loc9_:Station = null;
         var _loc10_:Station = null;
         var _loc25_:ShipManager = null;
         var _loc26_:Ship = null;
         var _loc27_:BufferedShip = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         var _loc4_:String = String(param1[6]);
         var _loc5_:Number = Number(param1[9]);
         var _loc6_:Number = Number(param1[10]);
         var _loc7_:RelayStation = new RelayStation(_loc2_,_loc3_,_loc4_,_loc5_,_loc6_,this.main.screenManager.map);
         _loc7_.mouseEnabled = true;
         _loc7_.x = _loc5_;
         _loc7_.y = _loc6_;
         this.main.screenManager.map.relayStationArray.push(_loc7_);
         this.main.screenManager.getShipLayer().addChild(_loc7_);
         var _loc8_:Array = this.main.screenManager.map.getStationManager().getStations();
         var _loc11_:int = 0;
         while(_loc11_ < _loc8_.length)
         {
            _loc9_ = _loc8_[_loc11_] as Station;
            if(_loc9_.getTypeID() == 4)
            {
               _loc10_ = _loc9_;
            }
            _loc11_++;
         }
         _loc7_.healthStation = _loc10_;
         var _loc12_:int = _loc2_;
         var _loc13_:int = 84;
         var _loc14_:int = 0;
         var _loc15_:String = "nan";
         var _loc16_:String = _loc4_;
         var _loc17_:int = Hero.factionID;
         var _loc18_:int = 1;
         var _loc19_:int = int(param1[11]);
         var _loc20_:Boolean = false;
         var _loc21_:int = 0;
         var _loc22_:int = 0;
         var _loc23_:Boolean = true;
         var _loc24_:Boolean = true;
         if(_loc13_ == 84 || _loc13_ == 85)
         {
            _loc14_ = 1;
         }
         _loc13_ = this.main.getConnectionManager().getMappedShipType(_loc13_);
         if(!Settings.createOpponents)
         {
            return;
         }
         if(_loc17_ > 3)
         {
            _loc17_ = 0;
         }
         if(_loc12_ == Hero.userID)
         {
            return;
         }
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc25_ = this.map.getShipManager();
            if(_loc25_ != null)
            {
               _loc26_ = _loc25_.createShip(_loc13_,_loc12_,_loc5_,_loc6_,1,_loc16_,_loc15_,_loc17_,_loc18_,_loc21_,_loc19_,_loc14_,_loc20_,_loc22_,_loc23_);
               if(_loc26_ != null)
               {
                  _loc26_.setCloak(_loc24_);
               }
               if(this.main.getConnectionManager()._watchedShipInits[_loc12_])
               {
                  this.main.getGroupManager().initMemberTarget(_loc12_);
               }
            }
         }
         else
         {
            _loc27_ = new BufferedShip(_loc13_,_loc12_,_loc5_,_loc6_,1,_loc16_,_loc15_,_loc17_,_loc18_,_loc21_,_loc19_,_loc14_,_loc20_,_loc22_,_loc23_,_loc24_);
            this.main.getConnectionManager().bufferedShips.push(_loc27_);
         }
      }
   }
}

