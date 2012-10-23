;;; Copyright (c) 2012, Jan Winkler <winkler@cs.uni-bremen.de>
;;; All rights reserved.
;;; 
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;; 
;;;     * Redistributions of source code must retain the above copyright
;;;       notice, this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright
;;;       notice, this list of conditions and the following disclaimer in the
;;;       documentation and/or other materials provided with the distribution.
;;;     * Neither the name of Willow Garage, Inc. nor the names of its
;;;       contributors may be used to endorse or promote products derived from
;;;       this software without specific prior written permission.
;;; 
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package :pr2-pick-and-place-scenario)

(defun prepare-scenario ()
  (fill-object-list)
  (simple-knowledge::spawn-objects))

(defun start-scenario (object-name)
  ;; Prepare the scenario
  (prepare-scenario)
  ;; Clear the attached objects
  (setf simple-belief::*attached-objects* nil)
  ;; Create an object designator from the object name and call the
  ;; actual scenario plan
  (let ((object-desig (desig:make-designator
                       'desig:object
                       `((name ,object-name)))))
    (pick-and-place-scenario object-desig)))

(def-top-level-cram-function pick-and-place-scenario (object-desig)
  (advertise-publishers)
  (with-process-modules
    ;; First, lift the spine. This way, we can access more parts of
    ;; the environment.
    (let ((spine-lift-trajectory (roslisp:make-msg
                                  "trajectory_msgs/JointTrajectory"
                                  (stamp header)
                                  (roslisp:ros-time)
                                  joint_names #("torso_lift_joint")
                                  points (vector
                                          (roslisp:make-message
                                           "trajectory_msgs/JointTrajectoryPoint"
                                           positions #(0.2)
                                           velocities #(0)
                                           accelerations #(0)
                                           time_from_start 5.0)))))
      (roslisp:ros-info (pick-and-place-scenario) "Moving up spine")
      (pr2-manip-pm::execute-torso-command spine-lift-trajectory)
      (roslisp:ros-info (pick-and-place-scenario) "Moving spine complete")
      (let* ((perceived-object (cram-plan-library:perceive-object
                                'cram-plan-library:a
                                object-desig))
             (former-obj-loc (desig-prop-value perceived-object 'at))
             (obj-in-hand (cram-designators:current-desig
                           (achieve `(cram-plan-knowledge:object-in-hand
                                      ,perceived-object)))))
        (declare (ignore former-obj-loc))
        obj-in-hand))))
        ;; (let ((obj-placed (achieve `(cram-plan-knowledge:object-placed-at
        ;;                              ,obj-in-hand
        ;;                              ,former-obj-loc))))
        ;(format t "Designator of placed object: ~a~%" obj-placed)))))
