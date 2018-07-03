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
            Vector3 positionVector = this.gameObject.transform.position;
            // TODO: Refactor this logic. 
            ObjectLogic.RenderWater.Radius = ObjectLogic.CalculateRadius(collision.impulse.y) / 12;
            Vector3[] conactPoints = new Vector3[2]
            {
                new Vector3(positionVector.x -0.5f, contactPoint.y, positionVector.z - 0.5f),
                new Vector3(positionVector.x + 0.5f, contactPoint.y, positionVector.z + 0.5f),    
            };
            ObjectLogic.RenderWater.WaterWaveQuadHappened(conactPoints);
            ObjectLogic.DestroyObject();
        }
    }
}
