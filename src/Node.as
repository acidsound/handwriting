/**
 * Created with IntelliJ IDEA.
 * User: acidsound
 * Date: 13. 5. 30.
 * Time: 오전 5:19
 * To change this template use File | Settings | File Templates.
 */
package {
import flash.geom.Point;

public class Node {
  private var _point:Point;
  private var _velocity:Point;
  public function Node(pt:Point, vel:Point) {
    _point = pt;
    _velocity = vel;
  }

  public function get velocity():Point {
    return _velocity;
  }

  public function get point():Point {
    return _point;
  }
}
}
