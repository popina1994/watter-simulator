using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerComponent : MonoBehaviour
{
    public Rigidbody rb;

	// Use this for initialization
	void Start ()
	{
         Debug.Log("Start");
	}
	
	// Update is called once per frame
	void FixedUpdate () {
	    rb.AddForce(0, 0, 2000 * Time.deltaTime);
    }
}
