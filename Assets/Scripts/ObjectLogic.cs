using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEditor.Experimental.Animations;
using UnityEngine;

namespace Assets.Scripts
{
    class ObjectLogic
    {
        private KeyCode _keyPressed;
        private SortedDictionary<KeyCode, Func<bool> > _keyAction;
        private GameObject _curGameObject = null;
        private static Vector3 INIT_POS = new Vector3(4, 3, -9);
        private const string PLAYER_MAT_NAME = "PlayerMat";
        private const float MOV_STEP = 0.1f;
        private RenderWater _renderWater;

        public RenderWater RenderWater
        {
            get { return _renderWater; }
            set { _renderWater = value; }
        }

        public ObjectLogic(RenderWater renderWater)
        {
            RenderWater = renderWater;
            KeyAction = new SortedDictionary<KeyCode, Func<bool>>();
            KeyAction.Add(KeyCode.C, CreateCube);
            KeyAction.Add(KeyCode.F, CreateSphere);
            KeyAction.Add(KeyCode.Z, DestroyObject);
            KeyAction.Add(KeyCode.W, MoveInScreen);
            KeyAction.Add(KeyCode.S, MoveFromScreen);
            KeyAction.Add(KeyCode.D, DropObject);
            KeyAction.Add(KeyCode.UpArrow, MoveUp);
            KeyAction.Add(KeyCode.LeftArrow, MoveLeft);
            KeyAction.Add(KeyCode.RightArrow, MoveRight);
            KeyAction.Add(KeyCode.DownArrow, MoveDown);
        }

        private bool MoveUp()
        {
            if (CurGameObject != null)
            {
                CurGameObject.transform.Translate(new Vector3(0, MOV_STEP, 0));
            }
            return true;
        }

        private bool MoveDown()
        {
            if (CurGameObject != null)
            {
                CurGameObject.transform.Translate(new Vector3(0, -MOV_STEP, 0));
            }
            
            return true;
        }

        private bool MoveRight()
        {
            if (CurGameObject != null)
            {
                CurGameObject.transform.Translate(new Vector3(MOV_STEP, 0, 0));
            }
            
            return true;
        }

        private bool MoveLeft()
        {
            if (CurGameObject != null)
            {
                CurGameObject.transform.Translate(new Vector3(-MOV_STEP, 0, 0));
            }
            
            return true;
        }

        private bool MoveInScreen()
        {
            if (CurGameObject != null)
            {
                CurGameObject.transform.Translate(new Vector3(0, 0, MOV_STEP));
            }

            return true;
        }

        private bool MoveFromScreen()
        {
            if (CurGameObject != null)
            {
                CurGameObject.transform.Translate(new Vector3(0, 0, -MOV_STEP));
            }

            return true;
        }

        public bool DestroyObject()
        {
            if (CurGameObject != null)
            {
                UnityEngine.Object.Destroy(CurGameObject);
            }
            CurGameObject= null;
            return true;
        }

        private void InitObject()
        {
            Material defaultMaterial = null;
            var z = Resources.FindObjectsOfTypeAll(typeof(Material));
            foreach (var it in Resources.FindObjectsOfTypeAll(typeof(Material)))
            {
                if (it.name == PLAYER_MAT_NAME)
                {
                    defaultMaterial = it as Material;
                    break;
                }
            }

            CurGameObject.transform.position = INIT_POS;
            CurGameObject.GetComponent<MeshRenderer>().material = defaultMaterial;
            Rigidbody rigidbody = CurGameObject.AddComponent<Rigidbody>() as Rigidbody;
            rigidbody.useGravity = false;
            rigidbody.mass = 1;
        }

        private bool CreateCube()
        {
            DestroyObject();
            CurGameObject = GameObject.CreatePrimitive(PrimitiveType.Cube);
            InitObject();
            CurGameObject.AddComponent<GameCube>();
            CurGameObject.GetComponent<GameCube>().ObjectLogic = this;
            return true;
        }

        private bool CreateSphere()
        {
            DestroyObject();
            CurGameObject = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            InitObject();
            CurGameObject.AddComponent<GameSphere>();
            CurGameObject.GetComponent<GameSphere>().ObjectLogic = this;
            return true;
        }

        private bool DropObject()
        {
            if (CurGameObject != null)
            {
                Rigidbody rigidbody = CurGameObject.GetComponent<Rigidbody>() as Rigidbody;
                rigidbody.useGravity = true;
            }

            return true;
        }

        public SortedDictionary<KeyCode, Func<bool>> KeyAction
        {
            get { return _keyAction; }
            private set { _keyAction = value; }
        }

        public KeyCode KeyPressed
        {
            get { return _keyPressed; }
            private set { _keyPressed = value; }
        }

        public GameObject CurGameObject
        {
            get { return _curGameObject; }
            set { _curGameObject = value; }
        }

        public void ProcessKeyPresses()
        {
            KeyAction[KeyPressed]();
        }

        public bool IsKeyPressed()
        {
            foreach (var it in KeyAction)
            {
                if (Input.GetKeyDown(it.Key))
                {
                    KeyPressed = it.Key;
                    return true;
                }
            }

            return false;
        }

        public float CalculateRadius(float impulse)
        {
            return impulse * 12;
        }
    }
}
