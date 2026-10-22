package net.bigpoint.darkorbit.net
{
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.audio.AudioManager;
   import net.bigpoint.darkorbit.combat.RocketPattern;
   import net.bigpoint.darkorbit.gui.container.SimpleContainer;
   import net.bigpoint.darkorbit.gui.elements.SimpleElement;
   import net.bigpoint.darkorbit.gui.windows.SimpleWindow;
   import net.bigpoint.darkorbit.menu.ActionButton;
   import net.bigpoint.darkorbit.menu.SuperActionButton;
   import net.bigpoint.darkorbit.settings.Settings;
   
   public class RocketLauncherAssembly extends BaseAssembly
   {
      
      private static var instance:RocketLauncherAssembly;
      
      private var delegateDict:Dictionary;
      
      private var main:Main;
      
      public function RocketLauncherAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("RocketLauncherAssembly is a Singleton and can only be accessed through RocketLauncherAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : RocketLauncherAssembly
      {
         if(instance == null)
         {
            instance = new RocketLauncherAssembly(hidden);
         }
         return instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.ROCKETLAUNCHER_STATUS] = this.assembleSetStatusCommand;
         this.delegateDict[ServerCommands.ROCKETLAUNCHER_STATUS_LOWER] = this.assembleSetStatusCommand;
         this.delegateDict[ServerCommands.ROCKETLAUNCHER_ATTACK] = this.assembleRocketLauncherAttackCommand;
         this.delegateDict[ServerCommands.ROCKETLAUNCHER_ATTACK_LOWER] = this.assembleRocketLauncherAttackCommand;
         this.delegateDict[ServerCommands.SET_ROCKETLAUNCHER_ROCKETS] = this.assembleSetRocketsCommand;
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      public function assembleRocketLauncherAttackCommand(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         var _loc4_:int = int(param1[5]);
         var _loc5_:int = int(param1[6]);
         var _loc6_:Boolean = false;
         if(param1[7] == "M")
         {
            _loc6_ = true;
         }
         if(_main.screenManager.map != null)
         {
            _main.screenManager.map.getCombatManager().addAirstrike(_loc2_,_loc3_,_loc5_,_loc4_,_loc6_);
         }
      }
      
      public function assembleSetRocketsCommand(param1:Array) : void
      {
         Hero.rocketAmounts[RocketPattern.HSTRM01] = int(param1[3]);
         Hero.rocketAmounts[RocketPattern.UBR100] = int(param1[4]);
         Hero.rocketAmounts[RocketPattern.ECO10] = int(param1[5]);
         _main.getGuiManager().updateInfoField(SimpleWindow.WINDOW_CLASS_SHIP,SimpleContainer.CONTAINER_CLASS_HERO_INFO_1,SimpleElement.TYPE_ROCKETS);
         _main.getGuiManager().getMenuManager().updateLauncherRocketButtonAmounts();
      }
      
      public function assembleSetStatusCommand(param1:Array) : void
      {
         var _loc3_:ActionButton = null;
         var _loc4_:int = 0;
         Settings.rocketLauncherType = int(param1[3]);
         Settings.selectedLauncherRocket = int(param1[4]);
         Settings.rocketLauncherRocketsLoaded = int(param1[5]);
         if(Settings.rocketLauncherType == 0)
         {
            Settings.rocketLauncherRocketsLoaded = 0;
            _main.getGuiManager().getMenuManager().updateRocketButtonAmounts();
         }
         else if(Settings.rocketLauncherType == 1)
         {
            if(Settings.rocketLauncherRocketsLoaded > 0 && Settings.rocketLauncherRocketsLoaded < 3)
            {
               AudioManager.playSoundEffect(46);
            }
            else if(Settings.rocketLauncherRocketsLoaded == 3)
            {
               AudioManager.playSoundEffect(47);
            }
         }
         else if(Settings.rocketLauncherType == 2)
         {
            if(Settings.rocketLauncherRocketsLoaded > 0 && Settings.rocketLauncherRocketsLoaded < 5)
            {
               AudioManager.playSoundEffect(46);
            }
            else if(Settings.rocketLauncherRocketsLoaded == 5)
            {
               AudioManager.playSoundEffect(47);
            }
         }
         var _loc2_:Array = _main.getGuiManager().getMenuManager().getActionButtonsByID(SuperActionButton.SELECTION_LOAD_ROCKET_LAUNCHER);
         if(_loc2_ != null && _loc2_.length > 0)
         {
            _loc4_ = 0;
            while(_loc4_ < _loc2_.length)
            {
               _loc3_ = _loc2_[_loc4_] as ActionButton;
               _loc3_.buttonDecorator.update();
               _loc3_.updateTooltip();
               _loc4_++;
            }
         }
      }
   }
}

