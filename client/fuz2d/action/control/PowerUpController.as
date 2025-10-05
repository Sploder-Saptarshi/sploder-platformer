/**
* Fuz2d: 2d Gaming Engine
* ----------------------------------------------------------------
* ----------------------------------------------------------------
* Copyright (C) 2008 Geoffrey P. Gaudreault
* 
*/

package fuz2d.action.control {
	
	import flash.events.Event;
	
	import fuz2d.action.physics.*;
	import fuz2d.action.play.*;
	import fuz2d.Fuz2d;
	import fuz2d.model.object.Symbol;
	import fuz2d.TimeStep;
	
	
	/**
	* ...
	* @author Geoff Gaudreault
	*/
	public class PowerUpController extends PlayObjectController {
		
		protected var _spent:Boolean = false;
		protected var _spendTime:int = 0;

		protected var _powerAttribName:String = "";
		protected var _isModifier:Boolean = false;
		protected var _global:Boolean = false;
		protected var _power:int = 0;
		protected var _restoreTime:int = -1;
		protected var _addToBelt:Boolean = false;
		protected var _spendAtEnd:Boolean = false;
		protected var _spendSound:String = "";
		
		public function get powerAttribName():String { return _powerAttribName; }
		public function get isModifier():Boolean { return _isModifier; }
		public function get power():int { return _power; }
		public function get addToBelt():Boolean { return _addToBelt; }

		public static var totals:Object;
		public static var counts:Object;
		
	//
	//
	public function PowerUpController (object:PlayObjectControllable, powerAttribName:String = "", isModifier:Boolean = false, global:Boolean = false, power:int = 0, restoreTime:int = -1, addToBelt:Boolean = false, spendAtEnd:Boolean = false, spendSound:String = "") {
	
		super(object);
		
		if (totals == null) totals = { };
		if (counts == null) counts = { };
		
		_powerAttribName = powerAttribName;
		_isModifier = isModifier;
		_global = global;
		_power = power;
		_restoreTime = restoreTime;
		_addToBelt = addToBelt;
		_spendAtEnd = spendAtEnd;
		_spendSound = spendSound;
		
		trace("PowerUpController constructor: powerAttribName=" + _powerAttribName + ", _global=" + _global);
		
		if (_global) {
			if (totals[_powerAttribName] == null) totals[_powerAttribName] = 0;
			totals[_powerAttribName]++;
			if (counts[_powerAttribName] == null) counts[_powerAttribName] = 0;
			counts[_powerAttribName]++;
			trace("PowerUpController constructor: Incremented " + _powerAttribName + " - totals=" + totals[_powerAttribName] + ", counts=" + counts[_powerAttribName]);
		}
		
		_object.simObject.addEventListener(CollisionEvent.COLLISION, onCollision, false, 0, true);
		
	}		//
		//
		override public function update (e:Event):void {
			
			if (_ended || !_active) return;
			
			super.update(e);
			
			if (_spent && _restoreTime > 0) {
				
				if (TimeStep.realTime - _spendTime >= _restoreTime) restore();
				
			}
				
		}
		
	public function spend (e:CollisionEvent):void {
		
		trace("PowerUpController.spend called: _spent=" + _spent + ", collider.type=" + e.collider.type + ", _powerAttribName=" + _powerAttribName);
		
		if (!_spent && e.collider.type == "player") {
			
			_spent = true;
			
			trace("PowerUpController.spend: _global=" + _global + ", counts=" + counts + ", counts[" + _powerAttribName + "]=" + counts[_powerAttribName]);
			
			// Ruffle compatibility: Always decrement for objective items (crystal, escapepod)
			// even if _global flag wasn't set properly
			var isObjectiveItem:Boolean = (_powerAttribName == "crystal" || _powerAttribName == "escapepod");
			
			if ((isObjectiveItem || _global) && counts != null && counts[_powerAttribName] != null) {
				var currentCount:int = int(counts[_powerAttribName]);
				counts[_powerAttribName] = currentCount - 1;
				trace("PowerUpController.spend: " + _powerAttribName + " count decremented from " + currentCount + " to " + counts[_powerAttribName]);
			} else {
				trace("PowerUpController.spend: SKIPPED decrement - _global=" + _global + ", isObjectiveItem=" + isObjectiveItem + ", counts null=" + (counts == null) + ", counts[" + _powerAttribName + "] null=" + (counts[_powerAttribName] == null));
			}
			
			if (!_spendAtEnd) {
				_object.playfield.dispatchEvent(new PlayfieldEvent(PlayfieldEvent.POWERUP, false, false, _object));
			}				Symbol(_object.object).state = "f_spent";
				_spendTime = TimeStep.realTime;
				
				if (_spendSound.length > 0) {
					Fuz2d.sounds.addSound(_object, _spendSound);
				}
				
			}
			
		}
		
		public function restore ():void {
			
			if (_restoreTime > 0) {
				
				_spent = false;
				Symbol(_object.object).state = "f_restore";
				
			}
			
		}
		
		//
		//
		protected function onCollision (e:CollisionEvent):void {
			
			if (powerAttribName == "health" && 
				e.collider.objectRef != null && 
				e.collider.objectRef.attribs.health != null && 
				e.collider.objectRef.attribs.health == 1) return;
				
			if (powerAttribName == "extralife" && GameLevel.lives >= 4) return;
				
			if (_isModifier) {
				
				var pobj:PlayObject = _object.playfield.playObjects[e.collider];
				
				if (pobj != null && pobj is PlayObjectControllable) {
					
					var pc:PlayObjectControllable = pobj as PlayObjectControllable;
					
					if (pc.modifiers.contains(_powerAttribName)) return;
					
				}
				
			}
				
			if (!_spent) spend(e);
			
		}
		
		//
		//
		override public function end():void {
			
			if (_spendAtEnd) {
				_object.playfield.dispatchEvent(new PlayfieldEvent(PlayfieldEvent.POWERUP, false, false, _object));
				_spendAtEnd = false;
			}
			if (_object != null && _object.simObject != null) _object.simObject.removeEventListener(CollisionEvent.COLLISION, onCollision);
			super.end();
			
		}
		
	}
	
}