//
//  ViewController.swift
//  study_integral_macos
//
//  Created by Hoàng Xuân Quang on 7/9/17.
//  Copyright © 2017 Hoang Xuan Quang. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let tests = TestClass()

//        tests.test_square()
        tests.test_square_integral()
        
//        assert(tests.testSmallTextureSum() == true)
//        assert(tests.compareImplAgainstMPSWithBounds() == true)
//        assert(tests.compareImplAgainstMPS() == true)
//        assert(tests.testTimes720p() == true)
//        assert(tests.testTimes1080p() == true)
//        print("Tests Completed")

        NSApp.terminate(nil)
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

