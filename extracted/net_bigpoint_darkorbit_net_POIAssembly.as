package net.bigpoint.darkorbit.net
{
   import flash.events.TimerEvent;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.map.Map;
   
   public class POIAssembly extends BaseAssembly
   {
      
      private static var instance:POIAssembly;
      
      private var main:Main;
      
      private var map:Map;
      
      private var delegateDict:Dictionary;
      
      private var damageTimer:Timer = new Timer(1000 * 2);
      
      private var shipID:int;
      
      public function POIAssembly()
      {
         super();
         if(instance)
         {
            throw new Error("Singleton and can only access with POIAssembly.getInstance()");
         }
         this.main = _main;
         this.map = this.main.screenManager.map;
         this.initDelegateDict();
      }
      
      public static function getInstance() : POIAssembly
      {
         if(instance == null)
         {
            instance = new POIAssembly();
         }
         return instance;
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.CREATE_POI] = this.assembleCreatePOI;
         this.delegateDict[ServerCommands.READY] = this.assemblePOIReady;
         this.delegateDict[ServerCommands.ENTER] = this.assembleEnterPOI;
         this.delegateDict[ServerCommands.LEAVE] = this.assembleLeavePOI;
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      private function assembleCreatePOI(param1:Array) : void
      {
         var _loc2_:String = String(param1[3]);
         var _loc3_:int = int(param1[4]);
         var _loc4_:int = int(param1[5]);
         var _loc5_:String = String(param1[6]);
         var _loc6_:Array = [];
         var _loc7_:int = 7;
         while(_loc7_ < param1.length)
         {
            _loc6_.push(param1[_loc7_]);
            _loc7_++;
         }
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.map.poiManager.addPOIZone(_loc2_,_loc3_,_loc5_,_loc4_,_loc6_);
         }
      }
      
      private function assemblePOIReady(param1:Array) : void
      {
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.map.poiManager.drawPOIZones();
         }
      }
      
      private function assembleEnterPOI(param1:Array) : void
      {
         if(param1[3] == ServerCommands.DAMAGE)
         {
            this.shipID = param1[4];
            this.damageTimer.start();
            this.damageTimer.addEventListener(TimerEvent.TIMER,this.startDamage);
         }
      }
      
      private function assembleLeavePOI(param1:Array) : void
      {
         if(param1[3] == ServerCommands.DAMAGE)
         {
            this.shipID = param1[4];
            this.damageTimer.stop();
            this.damageTimer.reset();
            this.damageTimer.removeEventListener(TimerEvent.TIMER,this.startDamage);
         }
      }
      
      private function startDamage(param1:TimerEvent) : void
      {
         this.map.getShipManager().getShip(this.shipID).addShipDamage("L");
      }
      
      public function cleanupShieldDamage() : void
      {
         this.damageTimer.stop();
         this.damageTimer.reset();
         this.damageTimer.removeEventListener(TimerEvent.TIMER,this.startDamage);
      }
   }
}

