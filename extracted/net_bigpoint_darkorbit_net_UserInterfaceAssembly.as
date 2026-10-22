package net.bigpoint.darkorbit.net
{
   import com.greensock.TweenLite;
   import flash.display.Sprite;
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.ScreenManager;
   import net.bigpoint.darkorbit.gui.GuiManager;
   import net.bigpoint.darkorbit.gui.elements.VideoElement;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.Ship;
   
   public class UserInterfaceAssembly extends BaseAssembly
   {
      
      private static var _instance:UserInterfaceAssembly;
      
      private var delegateDict:Dictionary;
      
      private var lockedShip:MapObject;
      
      private var main:Main;
      
      public function UserInterfaceAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("UserInterfaceAssembly is a Singleton and can only be accessed through UserInterfaceAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : UserInterfaceAssembly
      {
         if(_instance == null)
         {
            _instance = new UserInterfaceAssembly(hidden);
         }
         return _instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.CAMERA] = this.assembleCameraCommand;
         this.delegateDict[ServerCommands.MINIMAP] = this.assembleMinimapCommand;
         this.delegateDict[ServerCommands.ARROW] = this.assembleArrowCommand;
         this.delegateDict[ServerCommands.WINDOW] = this.assembleWindowCommand;
         this.delegateDict[ServerCommands.BUTTON] = this.assembleButtonCommand;
         this.delegateDict[ServerCommands.VIDEO_WINDOW] = this.assembleCommanderVideoWindowCommand;
         this.delegateDict[ServerCommands.SET_MENUBUTTON_ACCESS] = this.assembleMenuButtonAccessCommand;
         this.delegateDict[ServerCommands.SET_MENU_VISIBILITY] = this.assembleMenuVisibilityCommand;
         this.delegateDict[ServerCommands.CREATE_WINDOW] = this.assembleCreateWindowCommand;
         this.delegateDict[ServerCommands.DESTROY_WINDOW] = this.assembleDestroyWindowCommand;
         this.delegateDict[ServerCommands.ASSIST_WINDOW] = this.assembleHelpmovieWindowCommand;
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      private function assembleHelpmovieWindowCommand(param1:Array) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:String = null;
         var _loc7_:Boolean = false;
         var _loc8_:Array = null;
         var _loc9_:int = 0;
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:GuiManager = _main.getGuiManager();
         switch(param1[3])
         {
            case ServerCommands.CREATE_WINDOW:
               _loc4_ = int(param1[4]);
               _loc5_ = int(param1[5]);
               _loc6_ = param1[6];
               _loc7_ = Boolean(int(param1[7]));
               _loc8_ = [];
               _loc9_ = 8;
               while(_loc9_ < param1.length)
               {
                  _loc8_.push(param1[_loc9_]);
                  _loc9_++;
               }
               _loc3_.createVideoWindow(_loc8_,_loc4_,_loc5_,VideoElement.CLASS_HELPMOVIE,_loc7_,_loc6_);
               break;
            case ServerCommands.NEXT_PAGE:
               _loc4_ = int(param1[4]);
               _loc3_.showNextPageOfVideoWindow(_loc4_);
               break;
            case ServerCommands.DESTROY_WINDOW:
               _loc4_ = int(param1[4]);
               _loc3_.removeVideoWindow(_loc4_);
         }
      }
      
      private function assembleCreateWindowCommand(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:GuiManager = _main.getGuiManager();
         var _loc4_:String = param1[3];
         switch(_loc4_)
         {
            case ServerCommands.ADVERTISING_BANNER:
               _loc5_ = param1[6];
               _loc6_ = param1[7];
               _loc3_.createBannerWindow(_loc6_,_loc5_);
         }
      }
      
      private function assembleDestroyWindowCommand(param1:Array) : void
      {
         var _loc5_:String = null;
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:GuiManager = _main.getGuiManager();
         var _loc4_:String = param1[3];
         switch(_loc4_)
         {
            case ServerCommands.ADVERTISING_BANNER:
               _loc5_ = param1[4];
               _loc3_.removeBannerWindow(_loc5_);
         }
      }
      
      private function assembleMenuVisibilityCommand(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc2_:Array = [];
         _loc3_ = 4;
         while(_loc3_ < param1.length)
         {
            _loc2_.push(param1[_loc3_]);
            _loc3_++;
         }
         switch(param1[3])
         {
            case ServerCommands.SHOW_MENU:
               _loc3_ = 0;
               while(_loc3_ < _loc2_.length)
               {
                  _main.getGuiManager().getMenuManager().removeMenuFromBlacklist(_loc2_[_loc3_]);
                  _loc3_++;
               }
               break;
            case ServerCommands.HIDE_MENU:
               _loc3_ = 0;
               while(_loc3_ < _loc2_.length)
               {
                  _main.getGuiManager().getMenuManager().addMenuToBlacklist(_loc2_[_loc3_]);
                  _loc3_++;
               }
         }
      }
      
      private function assembleMenuButtonAccessCommand(param1:Array) : void
      {
         var _loc2_:Array = [];
         var _loc3_:int = 4;
         while(_loc3_ < param1.length)
         {
            _loc2_.push(param1[_loc3_]);
            _loc3_++;
         }
         switch(param1[3])
         {
            case ServerCommands.MENUBUTTON_ENABLED:
               _loc3_ = 0;
               while(_loc3_ < _loc2_.length)
               {
                  _main.getGuiManager().getMenuManager().removeMenuButtonFromBlacklist(_loc2_[_loc3_]);
                  _loc3_++;
               }
               break;
            case ServerCommands.MENUBUTTON_DISABLED:
               _loc3_ = 0;
               while(_loc3_ < _loc2_.length)
               {
                  _main.getGuiManager().getMenuManager().addMenuButtonToBlacklist(_loc2_[_loc3_]);
                  _loc3_++;
               }
         }
      }
      
      private function assembleCommanderVideoWindowCommand(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:String = null;
         var _loc6_:Boolean = false;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc2_:Map = _main.screenManager.map;
         switch(param1[3])
         {
            case ServerCommands.CREATE_VIDEO_WINDOW:
               _loc3_ = int(param1[4]);
               _loc4_ = int(param1[5]);
               _loc5_ = param1[6];
               _loc6_ = Boolean(int(param1[7]));
               _loc7_ = [];
               _loc8_ = 8;
               while(_loc8_ < param1.length)
               {
                  _loc7_.push(param1[_loc8_]);
                  _loc8_++;
               }
               if(_loc2_ != null)
               {
                  _loc2_.getMain().getGuiManager().createVideoWindow(_loc7_,_loc3_,_loc4_,VideoElement.CLASS_COMMANDER,_loc6_,_loc5_);
               }
               break;
            case ServerCommands.NEXT_PAGE:
               _loc3_ = int(param1[4]);
               _loc2_.getMain().getGuiManager().showNextPageOfVideoWindow(_loc3_);
               break;
            case ServerCommands.DESTROY_VIDEO_WINDOW:
               _loc3_ = int(param1[4]);
               _loc2_.getMain().getGuiManager().removeVideoWindow(_loc3_);
         }
      }
      
      private function assembleButtonCommand(param1:Array) : void
      {
         var _loc2_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Boolean = false;
         var _loc3_:Map = _main.screenManager.map;
         var _loc4_:int = 0;
         switch(param1[3])
         {
            case ServerCommands.SHOW_BUTTON:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().getMenuManager().removeButtonFromBlacklist(_loc2_);
                  _loc4_++;
               }
               break;
            case ServerCommands.HIDE_BUTTON:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().getMenuManager().addButtonToBlacklist(_loc2_);
                  _loc4_++;
               }
               break;
            case ServerCommands.SHOW_FLASH:
               _loc5_ = int(param1[4]);
               _loc6_ = Boolean(int(param1[5]));
               if(_loc3_ != null)
               {
                  _loc4_ = 6;
                  while(_loc4_ < param1.length)
                  {
                     _loc2_ = int(param1[_loc4_]);
                     if(_loc5_ == -1)
                     {
                        _loc3_.getMain().getGuiManager().getMenuManager().registerFlashingButton(_loc2_,_loc6_);
                     }
                     _loc3_.getMain().getGuiManager().getMenuManager().flashButtonIcon(_loc2_,_loc5_,_loc6_);
                     _loc3_.getMain().getGuiManager().getTopMenu().flashButtonIcon(_loc2_,_loc5_,_loc6_);
                     _loc4_++;
                  }
               }
               break;
            case ServerCommands.HIDE_FLASH:
               if(_loc3_ != null)
               {
                  _loc4_ = 6;
                  while(_loc4_ < param1.length)
                  {
                     _loc2_ = int(param1[_loc4_]);
                     _loc3_.getMain().getGuiManager().getMenuManager().unregisterFlashingButton(_loc2_);
                     _loc3_.getMain().getGuiManager().getMenuManager().stopFlashButtonIcon(_loc2_);
                     _loc3_.getMain().getGuiManager().getTopMenu().stopFlashButtonIcon(_loc2_);
                     _loc4_++;
                  }
               }
         }
      }
      
      private function assembleWindowCommand(param1:Array) : void
      {
         var _loc2_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Boolean = false;
         var _loc3_:Map = _main.screenManager.map;
         var _loc4_:int = 0;
         switch(param1[3])
         {
            case ServerCommands.SHOW_WINDOW:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().removeWindowFromBlacklist(_loc2_);
                  _loc4_++;
               }
               break;
            case ServerCommands.HIDE_WINDOW:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().addWindowToBlacklist(param1[_loc4_]);
                  _loc4_++;
               }
               break;
            case ServerCommands.MINIMIZE_WINDOW:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().minimizeWindow(_loc2_);
                  _loc4_++;
               }
               break;
            case ServerCommands.MAXIMIZE_WINDOW:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().maximizeWindow(_loc2_);
                  _loc4_++;
               }
               break;
            case ServerCommands.MINIMIZE_WINDOW:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().minimizeWindow(_loc2_);
                  _loc4_++;
               }
               break;
            case ServerCommands.MAXIMIZE_WINDOW:
               _loc4_ = 4;
               while(_loc4_ < param1.length)
               {
                  _loc2_ = int(param1[_loc4_]);
                  _main.getGuiManager().maximizeWindow(_loc2_);
                  _loc4_++;
               }
               break;
            case ServerCommands.SHOW_FLASH:
               _loc5_ = int(param1[4]);
               _loc6_ = Main.parseBooleanFromInt(param1[5]);
               if(_loc3_ != null)
               {
                  _loc4_ = 6;
                  while(_loc4_ < param1.length)
                  {
                     _loc2_ = int(param1[_loc4_]);
                     _loc3_.getMain().getGuiManager().flashWindowIcon(_loc2_,_loc5_,_loc6_);
                     _loc4_++;
                  }
               }
               break;
            case ServerCommands.HIDE_FLASH:
               if(_loc3_ != null)
               {
                  _loc4_ = 4;
                  while(_loc4_ < param1.length)
                  {
                     _loc2_ = int(param1[_loc4_]);
                     _loc3_.getMain().getGuiManager().stopFlashWindowIcon(_loc2_);
                     _loc4_++;
                  }
               }
         }
      }
      
      private function assembleArrowCommand(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc2_:Map = _main.screenManager.map;
         switch(param1[3])
         {
            case ServerCommands.SHOW_ARROW:
               _loc3_ = int(param1[4]);
               _loc4_ = int(param1[5]);
               if(_loc2_ != null)
               {
                  _loc2_.getMain().getGuiManager().showArrow(_loc3_,_loc4_);
               }
               break;
            case ServerCommands.HIDE_ARROW:
               if(_loc2_ != null)
               {
                  _loc2_.getMain().getGuiManager().hideArrow();
               }
         }
      }
      
      private function assembleMinimapCommand(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:Map = _main.screenManager.map;
         if(_loc2_ == null)
         {
            return;
         }
         switch(param1[3])
         {
            case ServerCommands.NOISE:
               _loc2_.getCombatManager().addEMPBolt();
               break;
            case ServerCommands.SHOW_MARKER:
               _loc3_ = int(param1[4]);
               _loc4_ = int(param1[5]);
               _loc5_ = int(param1[6]);
               _loc6_ = int(param1[7]);
               _loc2_.getMinimapManager().getMiniMap().addMapMarker(_loc3_,_loc4_,_loc5_,_loc6_);
               break;
            case ServerCommands.HIDE_MARKER:
               _loc3_ = int(param1[4]);
               _loc2_.getMinimapManager().getMiniMap().stopMapMarker(_loc3_);
         }
      }
      
      private function assembleCameraCommand(param1:Array) : void
      {
         var _loc2_:Map = null;
         var _loc3_:Ship = null;
         var _loc4_:int = 0;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Sprite = null;
         var _loc8_:Sprite = null;
         var _loc9_:Sprite = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         switch(param1[3])
         {
            case ServerCommands.CAMERA_LOCK_TO_HERO:
               if(ScreenManager.cameraLock == ScreenManager.CAMERA_TWEENING_TO_HERO || ScreenManager.cameraLock == ScreenManager.CAMERA_LOCKED_TO_HERO)
               {
                  break;
               }
               _loc2_ = _main.screenManager.map;
               if(_loc2_ != null)
               {
                  ScreenManager.cameraLock = ScreenManager.CAMERA_TWEENING_TO_HERO;
                  _loc3_ = _loc2_.getShipManager().getHero();
                  TweenLite.to(ScreenManager.camera,3,{
                     "x":_loc3_.x,
                     "y":_loc3_.y,
                     "onComplete":this.handleTweenToHero
                  });
                  _loc2_.getMain().screenManager.resetZoomFactor();
               }
               break;
            case ServerCommands.CAMERA_LOCK_TO_SHIP:
               _loc2_ = _main.screenManager.map;
               _loc4_ = int(param1[4]);
               _loc5_ = Number(param1[5]);
               _loc6_ = Number(param1[6]);
               if(_loc2_ != null)
               {
                  if(ScreenManager.cameraLock == ScreenManager.CAMERA_TWEENING_TO_SHIP || ScreenManager.cameraLock == ScreenManager.CAMERA_LOCKED_TO_SHIP)
                  {
                     if(this.lockedShip != null && this.lockedShip.getUserId() == _loc4_)
                     {
                        _loc2_.getMain().screenManager.zoomToFactor(_loc6_,_loc5_);
                        break;
                     }
                  }
                  _loc2_.getEventManager().lockControls();
                  _loc3_ = _loc2_.getShipManager().getHero();
                  _loc7_ = _loc2_.getMain().screenManager.getHeroLayer();
                  _loc8_ = _loc2_.getMain().screenManager.getShipLayer();
                  _loc9_ = _loc3_.getClipContainer();
                  if(_loc7_.contains(_loc9_))
                  {
                     _loc7_.removeChild(_loc9_);
                  }
                  _loc8_.addChild(_loc9_);
                  _loc3_.setCCPositionToRealPosition();
                  _loc2_.getMain().screenManager.zoomToFactor(_loc6_,_loc5_);
                  ScreenManager.cameraLock = ScreenManager.CAMERA_TWEENING_TO_SHIP;
                  this.lockedShip = _loc2_.getShipManager().getShip(_loc4_);
                  TweenLite.to(ScreenManager.camera,_loc6_,{
                     "dynamicProps":{
                        "x":this.getLockedShipXPos,
                        "y":this.getLockedShipYPos
                     },
                     "onComplete":this.handleTweenToShip,
                     "onCompleteParams":[this.lockedShip]
                  });
               }
               _main.getGuiManager().setArrowVisibility(false);
               break;
            case ServerCommands.CAMERA_LOCK_TO_COORDINATES:
               _loc2_ = _main.screenManager.map;
               if(_loc2_ != null)
               {
                  _loc10_ = int(param1[4]);
                  _loc11_ = int(param1[5]);
                  _loc6_ = Number(param1[6]);
                  _loc2_.getEventManager().lockControls();
                  _loc3_ = _loc2_.getShipManager().getHero();
                  _loc7_ = _loc2_.getMain().screenManager.getHeroLayer();
                  _loc8_ = _loc2_.getMain().screenManager.getShipLayer();
                  _loc9_ = _loc3_.getClipContainer();
                  if(_loc7_.contains(_loc9_))
                  {
                     _loc7_.removeChild(_loc9_);
                  }
                  _loc8_.addChild(_loc9_);
                  _loc3_.setCCPositionToRealPosition();
                  ScreenManager.cameraLock = ScreenManager.CAMERA_TWEENING_TO_COORDINATE;
                  TweenLite.to(ScreenManager.camera,_loc6_,{
                     "x":_loc10_,
                     "y":_loc11_,
                     "onComplete":this.handleTweenToCoordinate
                  });
               }
               _main.getGuiManager().setArrowVisibility(false);
         }
      }
      
      private function handleTweenToShip(param1:MapObject) : void
      {
         ScreenManager.lockedShipUserID = param1.getUserId();
         ScreenManager.cameraLock = ScreenManager.CAMERA_LOCKED_TO_SHIP;
      }
      
      private function handleTweenToCoordinate() : void
      {
         ScreenManager.lockedShipUserID = -1;
         ScreenManager.cameraLock = ScreenManager.CAMERA_LOCKED_TO_COORDINATE;
      }
      
      private function handleTweenToHero() : void
      {
         var _loc1_:Map = _main.screenManager.map;
         _loc1_.getEventManager().unlockControls();
         var _loc2_:Ship = _loc1_.getShipManager().getHero();
         var _loc3_:Sprite = _loc1_.getMain().screenManager.getHeroLayer();
         var _loc4_:Sprite = _loc1_.getMain().screenManager.getShipLayer();
         if(_loc4_.contains(_loc2_.getClipContainer()))
         {
            _loc4_.removeChild(_loc2_.getClipContainer());
            _loc3_.addChild(_loc2_.getClipContainer());
            _loc2_.setCCPositionToFakePosition();
         }
         ScreenManager.lockedShipUserID = -1;
         this.lockedShip = null;
         ScreenManager.cameraLock = ScreenManager.CAMERA_LOCKED_TO_HERO;
         _main.getGuiManager().setArrowVisibility(true);
      }
      
      private function getLockedShipXPos() : Number
      {
         return this.lockedShip.x;
      }
      
      private function getLockedShipYPos() : Number
      {
         return this.lockedShip.y;
      }
   }
}

