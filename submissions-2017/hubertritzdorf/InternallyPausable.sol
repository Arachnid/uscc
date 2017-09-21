// Note for judges:  Adapted from https://raw.githubusercontent.com/OpenZeppelin/zeppelin-solidity/master/contracts/lifecycle/Pausable.sol
// Used to protect against re-entrancy attacks
// See diff at http://diffbin.herokuapp.com/o4 

pragma solidity ^0.4.11;


/**
 * @title InternallyPausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract InternallyPausable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called to pause, triggers stopped state
   */
  function pause() whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called to unpause, returns to normal state
   */
  function unpause() whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

