using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts
{
    
    class GameCube : MonoBehaviour
    {
        private ObjectLogic _objectLogic;


        public ObjectLogic ObjectLogic
        {
            get { return _objectLogic; }
            set { _objectLogic = value; }
        }

        void OnCollisionEnter(Collision collision)
        {
            Vector3 contactPoint = collision.contacts[0].point;

            ObjectLogic.RenderWater.Radius = ObjectLogic.CalculateRadius(collision.impulse.y);
            Vector3[] conactPoints = new Vector3[4]
            {
                new Vector3(contactPoint.x - 0.8f, contactPoint.y, contactPoint.z - 0.5f),
                new Vector3(contactPoint.x - 0.8f, contactPoint.y, contactPoint.z + 0.5f),    
                new Vector3(contactPoint.x + 0.2f, contactPoint.y, contactPoint.z - 0.5f),
                new Vector3(contactPoint.x + 0.2f, contactPoint.y, contactPoint.z + 0.5f)
            };
            ObjectLogic.RenderWater.WaterWaveQuadHappened(conactPoints);
            ObjectLogic.DestroyObject();
        }
    }
}
