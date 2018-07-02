using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts
{
    class GameSphere : MonoBehaviour
    {
        private ObjectLogic _objectLogic;

        public ObjectLogic ObjectLogic
        {
            get { return _objectLogic; }
            set { _objectLogic = value; }
        }

        void OnCollisionEnter(Collision collision)
        {
            ContactPoint contactPoint = collision.contacts[0];
            ObjectLogic.RenderWater.Radius = ObjectLogic.CalculateRadius(collision.impulse.y);
            ObjectLogic.RenderWater.WaterWaveHappened(contactPoint.point);
            ObjectLogic.DestroyObject();
        }
    }
}
