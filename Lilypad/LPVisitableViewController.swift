//
//  LPVisitableViewController.swift
//  LilyPad-ios
//
//  Created by Ari Kardasis on 9/10/19.
//  Copyright © 2019 LilyPad. All rights reserved.
//

import Foundation
import Turbolinks
import UIKit


class LPVisitableViewController: Turbolinks.VisitableViewController {
    open override func viewWillAppear(_ animated: Bool) {
        self.navigationController!.isNavigationBarHidden = true
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visitableView.contentInset = UIEdgeInsets.zero
    }
}
