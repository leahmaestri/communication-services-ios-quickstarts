//
//  ContentView.swift
//  iOSVideo
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//
import SwiftUI
import AzureCommunicationCommon
import AzureCommunicationCalling
import AVFoundation
import Foundation
import PushKit
import os.log
import CallKit

enum CreateCallAgentErrors: Error {
    case noToken
    case callKitInSDKNotSupported
}

struct JwtPayload: Decodable {
    var skypeid: String
    var exp: UInt64
}

struct ContentView: View {
    init(appPubs: AppPubs) {
        self.appPubs = appPubs
    }

    private let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ACSVideoSample")
    //private let token = "<USER_ACCESS_TOKEN>"
    private let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjVFODQ4MjE0Qzc3MDczQUU1QzJCREU1Q0NENTQ0ODlEREYyQzRDODQiLCJ4NXQiOiJYb1NDRk1kd2M2NWNLOTVjelZSSW5kOHNUSVEiLCJ0eXAiOiJKV1QifQ.eyJza3lwZWlkIjoiYWNzOmI2YWFkYTFmLTBiMWQtNDdhYy04NjZmLTkxYWFlMDBhMWQwMV8wMDAwMDAxOS1hOTVkLTJmYjYtODVmNC0zNDNhMGQwMDgyNTUiLCJzY3AiOjE3OTIsImNzaSI6IjE2ODgwODEyMzgiLCJleHAiOjE2ODgxNjc2MzgsInJnbiI6ImFtZXIiLCJhY3NTY29wZSI6InZvaXAiLCJyZXNvdXJjZUlkIjoiYjZhYWRhMWYtMGIxZC00N2FjLTg2NmYtOTFhYWUwMGExZDAxIiwicmVzb3VyY2VMb2NhdGlvbiI6InVuaXRlZHN0YXRlcyIsImlhdCI6MTY4ODA4MTIzOH0.mnWx-tKJTAZBqH4OJt4tDjLPQtL19lJT9PTcT4m5PMj22HKytjUG3n3IUlmQcRpdwXPQvLPUV1sXvESoUM834xEU2d4EIiQrhfiksrgzr59WZb5RkM7YRkwbky16vN1NG6YjcpYeTyu4ud5vwlz6vMpG7OmfOhKVKaTi9xr4ajUnh_DSrGdUFU6YX0BXeJi7coY8o2uMEbr0LhqJep2XQq6IfdiW8ZgIHEIPxmxpYCnl37t5uAHRwG25NddxaBjmt7suSQb58eEe_G5OTyFHg5eDRSkKQAAojhYWAfnKQZur-kRm6ZkZ9I6Fvv2gKUe4TSAFGb5ciZYhP1a_sYcWKw"
    private let cteToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjVFODQ4MjE0Qzc3MDczQUU1QzJCREU1Q0NENTQ0ODlEREYyQzRDODQiLCJ4NXQiOiJYb1NDRk1kd2M2NWNLOTVjelZSSW5kOHNUSVEiLCJ0eXAiOiJKV1QifQ.eyJza3lwZWlkIjoib3JnaWQ6ZDliZmFhNTktNjU0Yi00Y2ZlLThhZDMtZDg4N2E3ZjJhMTUwIiwic2NwIjoxMDI0LCJjc2kiOiIxNjg4MDc5MTY5IiwiZXhwIjoxNjg4MDg0MTEyLCJyZ24iOiJhbWVyIiwidGlkIjoiYmM2MWY0ZmMtMjZkNy00MTFlLTkxYTktNGMxNDY5MWRhYmRmIiwiYWNzU2NvcGUiOiJ2b2lwLGNoYXQiLCJyZXNvdXJjZUlkIjoiYjZhYWRhMWYtMGIxZC00N2FjLTg2NmYtOTFhYWUwMGExZDAxIiwiaWF0IjoxNjg4MDc5NDY5fQ.kjGm7rkbUg_X8W3N0hp9nGLWRov57B4Y2vdm3xlG59dgv_R_OVOq2v9wC-3q-YSB8hlhDnxD74fQWYyPr9YXpemEjXQqIBINQkM88-ezQcyYjfX6vWTzY4ydIPmgE2CTy4AxrDVuy77Qg0OTEdw-wU_NBIz3iIzEqHjLBqPAphS76H30UWDgJ3re2iEnkCrXQ7oxuQ7q559DvOw3Rtp0RoERRcT9__ORM0MjwoB1KSGd3iclkBk2X51d-67QNqiHOmaYcwC_j4vwmczJMd8yZjB0Z1N-A6cUZyKkgaJC2F5xm519T9juI0DLjoR4aPWhYZ4FAB5kn9U15F0NUvDcDw"
    
    @State var callee: String = "29228d3e-040e-4656-a70e-890ab4e173e4"
    @State var callClient = CallClient()

    @State var callAgent: CallAgent?
    @State var call: Call?
    @State var incomingCall: IncomingCall?
    @State var incomingCallHandler: IncomingCallHandler?
    @State var callHandler:CallHandler?

    @State var teamsCallAgent : TeamsCallAgent?
    @State var teamsCall: TeamsCall?
    @State var teamsIncomingCall: TeamsIncomingCall?
    @State var teamsIncomingCallHandler: TeamsIncomingCallHandler?
    @State var teamsCallHandler:TeamsCallHandler?

    @State var deviceManager: DeviceManager?
    @State var localVideoStream = [LocalVideoStream]()
    @State var sendingVideo:Bool = false
    @State var errorMessage:String = "Unknown"

    @State var remoteVideoStreamData:[RemoteVideoStreamData] = []
    @State var previewRenderer:VideoStreamRenderer? = nil
    @State var previewView:RendererView? = nil
    @State var remoteParticipant: RemoteParticipant?
    @State var remoteVideoSize:String = "Unknown"
    @State var isIncomingCall:Bool = false
    @State var showAlert = false
    @State var alertMessage = ""
    @State var userDefaults: UserDefaults = .standard
    @State var isSpeakerOn:Bool = false
    @State var isCte:Bool = false
    @State var isMuted:Bool = false
    @State var isHeld: Bool = false
    @State var mri: String = ""
    
    @State var callState: String = "None"
    @State var cxProvider: CXProvider?
    @State var remoteParticipantObserver:RemoteParticipantObserver?
    @State var pushToken: Data?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var appPubs: AppPubs

    var body: some View {
        HStack {
            Form {
                Section {
                    TextField("Who would you like to call?", text: $callee)
                    Button(action: startCall) {
                        Text("Start Call")
                    }.disabled(callAgent == nil && teamsCallAgent == nil)
                    Button(action: holdCall) {
                        Text(isHeld ? "Resume" : "Hold")
                    }.disabled(call == nil && teamsCall == nil)
                    Button(action: switchMicrophone) {
                        Text(isMuted ? "UnMute" : "Mute")
                    }.disabled(call == nil && teamsCall == nil)
                    Button(action: endCall) {
                        Text("End Call")
                    }.disabled(call == nil && teamsCall == nil)
                    Button(action: toggleLocalVideo) {
                        HStack {
                            Text(sendingVideo ? "Turn Off Video" : "Turn On Video")
                        }
                    }
                    VStack {
                        Toggle("CTE", isOn: $isCte)
                            .onChange(of: isCte) { _ in
                                createCallAgent(completionHandler: nil)
                            }.disabled(call != nil && teamsCall != nil)
                        Toggle("Speaker", isOn: $isSpeakerOn)
                            .onChange(of: isSpeakerOn) { _ in
                                switchSpeaker()
                            }.disabled(call == nil && teamsCall == nil)
                        TextField("Call State", text: $callState)
                            .foregroundColor(.red)
                        TextField("MRI", text: $mri)
                            .foregroundColor(.blue)
                    }
                }
            }
            if (isIncomingCall) {
                HStack() {
                    VStack {
                        Text("Incoming call")
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    Button(action: answerIncomingCall) {
                        HStack {
                            Text("Answer")
                        }
                        .frame(width:80)
                        .padding(.vertical, 10)
                        .background(Color(.green))
                    }
                    Button(action: declineIncomingCall) {
                        HStack {
                            Text("Decline")
                        }
                        .frame(width:80)
                        .padding(.vertical, 10)
                        .background(Color(.red))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(10)
                .background(Color.gray)
            }
            ZStack {
                VStack {
                    ForEach(remoteVideoStreamData, id:\.self) { remoteVideoStreamData in
                        ZStack{
                            VStack{
                                RemoteVideoView(view: remoteVideoStreamData.rendererView!)
                                    .frame(width: .infinity, height: .infinity)
                                    .background(Color(.lightGray))
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                VStack {
                    if(sendingVideo)
                    {
                        VStack{
                            PreviewVideoStream(view: previewView!)
                                .frame(width: 135, height: 240)
                                .background(Color(.lightGray))
                        }
                    }
                }.frame(maxWidth:.infinity, maxHeight:.infinity,alignment: .bottomTrailing)
            }
     .navigationBarTitle("Video Calling Quickstart")
        }
        .onReceive(self.appPubs.$pushToken, perform: { newPushToken in
            guard let newPushToken = newPushToken else {
                print("Got empty token")
                return
            }

            if let existingToken = self.pushToken {
                if existingToken != newPushToken {
                    self.pushToken = newPushToken
                }
            } else {
                self.pushToken = newPushToken
            }
        })
    .onReceive(self.appPubs.$pushPayload, perform: { payload in
            handlePushNotification(payload)
        })
     .onAppear{
            isSpeakerOn = userDefaults.value(forKey: "isSpeakerOn") as? Bool ?? false
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                if granted {
                    AVCaptureDevice.requestAccess(for: .video) { (videoGranted) in
                        /* NO OPERATION */
                    }
                }
            }

            if deviceManager == nil {
                self.callClient.getDeviceManager { (deviceManager, error) in
                    if (error == nil) {
                        print("Got device manager instance")
                        // This app does not support landscape mode
                        // But iOS still generates the device orientation events
                        // This is a work-around so that iOS stops generating those events
                        // And stop sending it to the SDK.
                        UIDevice.current.endGeneratingDeviceOrientationNotifications()
                        self.deviceManager = deviceManager
                    } else {
                        self.showAlert = true
                        self.alertMessage = "Failed to get DeviceManager"
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) { () -> Alert in
            Alert(title: Text("ERROR"), message: Text(alertMessage), dismissButton: .default(Text("Dismiss")))
        }
    }

    func switchMicrophone() {
        var callBase: CallBase?
        
        if let call = self.call {
            callBase = call
        } else if let teamsCall = self.teamsCall {
            callBase = teamsCall
        }

        guard let callBase = callBase else {
            self.showAlert = true
            self.alertMessage = "Failed to mute microphone, no call object"
            return
        }

        if self.isMuted {
            callBase.unmuteOutgoingAudio() { error in
                if error == nil {
                    isMuted = false
                } else {
                    self.showAlert = true
                    self.alertMessage = "Failed to unmute audio"
                }
            }
        } else {
            callBase.muteOutgoingAudio() { error in
                if error == nil {
                    isMuted = true
                } else {
                    self.showAlert = true
                    self.alertMessage = "Failed to mute audio"
                }
            }
        }
        userDefaults.set(isMuted, forKey: "isMuted")
    }

    func switchSpeaker() -> Void {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if isSpeakerOn {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            } else {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            }
            isSpeakerOn = !isSpeakerOn
            userDefaults.set(self.isSpeakerOn, forKey: "isSpeakerOn")
        } catch {
            self.showAlert = true
            self.alertMessage = "Failed to switch speaker: code: \(error.localizedDescription)"
        }
    }

    private func createCallAgentOptions() -> CallAgentOptions {
        let options = CallAgentOptions()
        options.callKitOptions = createCallKitOptions()
        return options
    }

    private func createTeamsCallAgentOptions() -> TeamsCallAgentOptions {
        let options = TeamsCallAgentOptions()
        options.callKitOptions = createCallKitOptions()
        return options
    }

    private func createCallKitOptions() -> CallKitOptions {
        let callKitOptions = CallKitOptions(with: CallKitHelper.createCXProvideConfiguration())
        callKitOptions.provideRemoteInfo = self.provideCallKitRemoteInfo
        return callKitOptions
    }
    
    func provideCallKitRemoteInfo(callerInfo: CallerInfo) -> CallKitRemoteInfo
    {
        let callKitRemoteInfo = CallKitRemoteInfo()
        callKitRemoteInfo.displayName = "CALL_TO_PHONENUMBER_BY_APP"
        callKitRemoteInfo.handle = CXHandle(type: .generic, value: "VALUE_TO_CXHANDLE")
        return callKitRemoteInfo
    }

    public func handlePushNotification(_ pushPayload: PKPushPayload?)
    {
        guard let pushPayload = pushPayload else {
            print("Got empty payload")
            return
        }

        if pushPayload.dictionaryPayload.isEmpty {
            os_log("ACS SDK got empty dictionary in push payload", log:self.log)
            return
        }

        let callNotification = PushNotificationInfo.fromDictionary(pushPayload.dictionaryPayload)

        let handlePush : (() -> Void) = {
            var callAgentBase: CallAgentBase?
            
            if let callAgent = self.callAgent {
                callAgentBase = callAgent
            } else if let teamsCallAgent = self.teamsCallAgent {
                callAgentBase = teamsCallAgent
            }
            // CallAgent is created normally handle the push
            callAgentBase!.handlePush(notification: callNotification) { (error) in
                if error == nil {
                    os_log("SDK handle push notification normal mode: passed", log:self.log)
                } else {
                    os_log("SDK handle push notification normal mode: failed", log:self.log)
                }
            }
        }

        createCallAgent { error in
            handlePush()
        }
    }

    private func registerForPushNotification() {
        if let callAgent = self.callAgent,
           let pushToken = self.pushToken {
            callAgent.registerPushNotifications(deviceToken: pushToken) { error in
                if error != nil {
                    self.showAlert = true
                    self.alertMessage = "Failed to register for Push"
                }
            }
        }
    }

    private func getMri(recvdToken: String) -> String {
        let tokenParts = recvdToken.components(separatedBy: ".")
        var token =  tokenParts[1]
        token = token.replacingOccurrences(of: "-", with: "+")
                     .replacingOccurrences(of: "_", with: "-")
                     .appending(String(repeating: "=", count: (4 - (token.count % 4)) % 4))

        if let data = Data(base64Encoded: token) {
            do {
                let payload = try JSONDecoder().decode(JwtPayload.self, from: data)
                return "8:\(payload.skypeid)"
            } catch {
                return "Invalid Token"
            }
        } else {
            return "Failed to parse"
        }
    }

    private func createCallAgent(completionHandler: ((Error?) -> Void)?) {
        DispatchQueue.main.async {
            if isCte {
                if teamsCallAgent != nil {
                    completionHandler?(nil)
                }
                #if BETA
                var userCredential: CommunicationTokenCredential
                do {
                    userCredential = try CommunicationTokenCredential(token: cteToken)
                } catch {
                    self.showAlert = true
                    self.alertMessage = "Failed to create CommunicationTokenCredential for Teams"
                    completionHandler?(CreateCallAgentErrors.noToken)
                    return
                }

                //mri = getMri(recvdToken: token)
                callClient.createTeamsCallAgent(userCredential: userCredential,
                                                options: createTeamsCallAgentOptions()) { (agent, error) in
                    if error == nil {
                        self.teamsCallAgent = agent
                        self.cxProvider = nil
                        print("Teams Call agent successfully created.")
                        teamsIncomingCallHandler = TeamsIncomingCallHandler(contentView: self)
                        self.teamsCallAgent!.delegate = teamsIncomingCallHandler
                        registerForPushNotification()
                    } else {
                        self.showAlert = true
                        self.alertMessage = "Failed to create CallAgent (with CallKit) : \(error?.localizedDescription ?? "Empty Description")"
                    }
                    completionHandler?(error)
                }
                
                #else
                self.showAlert = true
                self.alertMessage = "Cannot create CTE CallAgent in GA"
                completionHandler?(CreateCallAgentErrors.noToken)
                return
                #endif
            } else {
                if callAgent != nil {
                    completionHandler?(nil)
                }

                var userCredential: CommunicationTokenCredential
                do {
                    userCredential = try CommunicationTokenCredential(token: token)
                } catch {
                    self.showAlert = true
                    self.alertMessage = "Failed to create CommunicationTokenCredential"
                    completionHandler?(CreateCallAgentErrors.noToken)
                    return
                }
                
                mri = getMri(recvdToken: token)
                if callAgent != nil {
                    // Have to dispose existing CallAgent if present
                    // Because we cannot create two CallAgent's
                    callAgent!.dispose()
                    callAgent = nil
                }
                
                self.callClient.createCallAgent(userCredential: userCredential,
                                                options: createCallAgentOptions()) { (agent, error) in
                    if error == nil {
                        self.callAgent = agent
                        self.cxProvider = nil
                        print("Call agent successfully created.")
                        incomingCallHandler = IncomingCallHandler(contentView: self)
                        self.callAgent!.delegate = incomingCallHandler
                        registerForPushNotification()
                    } else {
                        self.showAlert = true
                        self.alertMessage = "Failed to create CallAgent (with CallKit) : \(error?.localizedDescription ?? "Empty Description")"
                    }
                    completionHandler?(error)
                }
            }
        }
    }

    func declineIncomingCall() {
        guard let incomingCall = self.incomingCall else {
            self.showAlert = true
            self.alertMessage = "No incoming call to reject"
            return
        }

        incomingCall.reject { (error) in
            guard let rejectError = error else {
                return
            }
            self.showAlert = true
            self.alertMessage = rejectError.localizedDescription
            isIncomingCall = false
        }
    }

    func showIncomingCallBanner(_ incomingCall: IncomingCallBase?) {
        guard let incomingCallBase = incomingCall else {
            return
        }
        isIncomingCall = true
        if incomingCallBase is IncomingCall {
            self.incomingCall = (incomingCallBase as! IncomingCall)
        } else if incomingCall is TeamsIncomingCall {
            self.teamsIncomingCall = (incomingCall as! TeamsIncomingCall)
        }        
    }

    func answerIncomingCall() {
        isIncomingCall = false
        let options = AcceptCallOptions()
        guard let deviceManager = deviceManager else {
            self.showAlert = true
            self.alertMessage = "Failed to get device manager when trying to answer call"
            return
        }

        localVideoStream.removeAll()

        if(sendingVideo) {
            let camera = deviceManager.cameras.first
            let outgoingVideoOptions = OutgoingVideoOptions()
            outgoingVideoOptions.streams.append(LocalVideoStream(camera: camera!))
            options.outgoingVideoOptions = outgoingVideoOptions
        }

        if isCte {
            guard let teamsIncomingCall = self.teamsIncomingCall else {
                self.showAlert = true
                self.alertMessage = "No teams incoming call to reject"
                return
            }
            
            teamsIncomingCall.accept(options: options) { teamsCall, error in
                setTeamsCallAndObserver(teamsCall: teamsCall, error: error)
            }
        } else {
            guard let incomingCall = self.incomingCall else {
                return
            }
            
            incomingCall.accept(options: options) { (call, error) in
                setCallAndObersever(call: call, error: error)
            }
        }
    }

    func callRemoved(_ call: CallBase) {
        self.call = nil
        self.incomingCall = nil
        for data in remoteVideoStreamData {
            data.renderer?.dispose()
        }
        self.previewRenderer?.dispose()
        remoteVideoStreamData.removeAll()
        sendingVideo = false
    }

    private func createLocalVideoPreview() -> Bool {
        guard let deviceManager = self.deviceManager else {
            self.showAlert = true
            self.alertMessage = "No DeviceManager instance exists"
            return false
        }

        let scalingMode = ScalingMode.fit
        localVideoStream.removeAll()
        localVideoStream.append(LocalVideoStream(camera: deviceManager.cameras.first!))
        previewRenderer = try! VideoStreamRenderer(localVideoStream: localVideoStream.first!)
        previewView = try! previewRenderer!.createView(withOptions: CreateViewOptions(scalingMode:scalingMode))
        self.sendingVideo = true
        return true
    }

    func toggleLocalVideo() {
        guard let call = self.call else {
            if(!sendingVideo) {
                _ = createLocalVideoPreview()
            } else {
                self.sendingVideo = false
                self.previewView = nil
                self.previewRenderer!.dispose()
                self.previewRenderer = nil
            }
            return
        }

        if (sendingVideo) {
            call.stopVideo(stream: localVideoStream.first!) { (error) in
                if (error != nil) {
                    print("Cannot stop video")
                } else {
                    self.sendingVideo = false
                    self.previewView = nil
                    self.previewRenderer!.dispose()
                    self.previewRenderer = nil
                }
            }
        } else {
            if createLocalVideoPreview() {
                call.startVideo(stream:(localVideoStream.first)!) { (error) in
                    if (error != nil) {
                        print("Cannot send local video")
                    }
                }
            }
        }
    }

    func holdCall() {
        guard let call = self.call else {
            self.showAlert = true
            self.alertMessage = "No active call to hold/resume"
            return
        }
        
        if self.isHeld {
            call.resume { error in
                if error == nil {
                    self.isHeld = false
                }  else {
                    self.showAlert = true
                    self.alertMessage = "Failed to hold the call"
                }
            }
        } else {
            call.hold { error in
                if error == nil {
                    self.isHeld = true
                } else {
                    self.showAlert = true
                    self.alertMessage = "Failed to resume the call"
                }
            }
        }
    }

    func startCall() {
        Task {
            var callOptions: CallOptions?
            var meetingLocator: JoinMeetingLocator?
            var callees:[CommunicationIdentifier] = []
            
            if (self.callee.starts(with: "8:")) {
                let calleesRaw = self.callee.split(separator: ";")
                for calleeRaw in calleesRaw {
                    callees.append(CommunicationUserIdentifier(String(calleeRaw)))
                }
                if isCte {
                    if callees.count == 1 {
                        callOptions = StartTeamsCallOptions()
                    } else if callees.count > 1 {
                        // When starting a call with multiple participants , need to pass a thread ID
                        callOptions = StartTeamsGroupCallOptions(threadId: UUID())
                    }
                } else {
                    callOptions = StartCallOptions()
                }
            } else if let groupId = UUID(uuidString: self.callee) {
                if isCte {
                    self.showAlert = true
                    self.alertMessage = "CTE does not support group call"
                    return
                } else {
                    let groupCallLocator = GroupCallLocator(groupId: groupId)
                    meetingLocator = groupCallLocator
                    callOptions = JoinCallOptions()
                }
            } else if (self.callee.starts(with: "https:")) {
                let teamsMeetingLinkLocator = TeamsMeetingLinkLocator(meetingLink: self.callee)
                callOptions = JoinCallOptions()
                meetingLocator = teamsMeetingLinkLocator
            }

            let outgoingVideoOptions = OutgoingVideoOptions()
            
            if(sendingVideo)
            {
                guard let deviceManager = self.deviceManager else {
                    self.showAlert = true
                    self.alertMessage = "No DeviceManager instance exists"
                    return
                }
                
                localVideoStream.removeAll()
                localVideoStream.append(LocalVideoStream(camera: deviceManager.cameras.first!))
                outgoingVideoOptions.streams = localVideoStream
            }

            callOptions!.outgoingVideoOptions = outgoingVideoOptions

            if isCte {
                guard let teamsCallAgent = self.teamsCallAgent else {
                    self.showAlert = true
                    self.alertMessage = "No Teams CallAgent instance exists to place the call"
                    return
                }
                
                do {
                    var teamsCall: TeamsCall?
                    if callee.count == 1 && self.callee.starts(with: "https:") {
                        let teamsCall = try await teamsCallAgent.join(teamsMeetingLinkLocator: meetingLocator! as! TeamsMeetingLinkLocator, joinCallOptions: callOptions! as! JoinCallOptions)
                    } else {
                        if callees.count == 1 {
                            teamsCall = try await teamsCallAgent.startCall(participant: callees.first!, options: (callOptions! as! StartTeamsCallOptions))
                        } else if callees.count > 1 {
                            teamsCall = try await teamsCallAgent.startCall(participants: callees, options: (callOptions! as! StartTeamsGroupCallOptions))
                        }
                    }
                    setTeamsCallAndObserver(teamsCall: teamsCall, error: nil)
                } catch {
                    setTeamsCallAndObserver(teamsCall: nil, error: error)
                }
            } else {
                guard let callAgent = self.callAgent else {
                    self.showAlert = true
                    self.alertMessage = "No CallAgent instance exists to place the call"
                    return
                }
                
                do {
                    var call: Call?
                    if self.callee.starts(with: "https:") {
                        call = try await callAgent.join(with: meetingLocator!, joinCallOptions: (callOptions! as! JoinCallOptions))
                    } else if UUID(uuidString: self.callee) != nil {
                        call = try await callAgent.join(with: meetingLocator as! GroupCallLocator, joinCallOptions: (callOptions! as! JoinCallOptions))
                    } else {
                        call = try await callAgent.startCall(participants: callees, options: (callOptions! as! StartCallOptions))
                    }
                    setCallAndObersever(call: call, error: nil)
                } catch {
                    setCallAndObersever(call: nil, error: error)
                }
            }
        }
    }

    func setCallAndObersever(call: Call?, error:Error?) {

        guard let call = call else {
            self.showAlert = true
            self.alertMessage = "Failed to get Call"
            return
        }

        self.call = call
        self.callHandler = CallHandler(self)
        self.call!.delegate = self.callHandler
        self.remoteParticipantObserver = RemoteParticipantObserver(self)
        switchSpeaker()
    }
    
    func setTeamsCallAndObserver(teamsCall: TeamsCall? , error: Error?) {
        guard let teamsCall = teamsCall else {
            self.showAlert = true
            self.alertMessage = "Failed to get Teams Call"
            return
        }

        self.teamsCall = teamsCall
        self.teamsCallHandler = TeamsCallHandler(self)
        self.teamsCall!.delegate = self.teamsCallHandler
        self.remoteParticipantObserver = RemoteParticipantObserver(self)
        switchSpeaker()
    }

    func endCall() {
        var callBase: CallBase?
        
        if call != nil {
            callBase = call
        } else if teamsCall != nil {
            callBase = teamsCall
        }
    
        callBase?.hangUp(options: HangUpOptions()) { (error) in
            if (error != nil) {
                print("ERROR: It was not possible to hangup the call.")
            }
        }
        self.previewRenderer?.dispose()
        sendingVideo = false
        isSpeakerOn = false
    }
}

public class RemoteVideoStreamData : NSObject, RendererDelegate {
    public func videoStreamRenderer(didFailToStart renderer: VideoStreamRenderer) {
        owner.errorMessage = "Renderer failed to start"
    }

    private var owner:ContentView
    let stream:RemoteVideoStream
    var renderer:VideoStreamRenderer? {
        didSet {
            if renderer != nil {
                renderer!.delegate = self
            }
        }
    }

    var rendererView: RendererView?

    init(view:ContentView, stream:RemoteVideoStream) {
        owner = view
        self.stream = stream
    }

    public func videoStreamRenderer(didRenderFirstFrame renderer: VideoStreamRenderer) {
        let size:StreamSize = renderer.size
        owner.remoteVideoSize = String(size.width) + " X " + String(size.height)
    }
}

public class RemoteParticipantObserver : NSObject, RemoteParticipantDelegate {
    private var owner:ContentView
    init(_ view:ContentView) {
        owner = view
    }

    public func renderRemoteStream(_ stream: RemoteVideoStream!) {
        let data:RemoteVideoStreamData = RemoteVideoStreamData(view: owner, stream: stream)
        let scalingMode = ScalingMode.fit
        do {
            data.renderer = try VideoStreamRenderer(remoteVideoStream: stream)
            let view:RendererView = try data.renderer!.createView(withOptions: CreateViewOptions(scalingMode:scalingMode))
            owner.remoteVideoStreamData.append(data)
            data.rendererView = view
        } catch let error as NSError {
            self.owner.alertMessage = error.localizedDescription
            self.owner.showAlert = true
        }
    }

    
    public func remoteParticipant(_ remoteParticipant: RemoteParticipant, didChangeVideoStreamState args: VideoStreamStateChangedEventArgs) {
        print("Remote Video Stream state for videoId: \(args.stream.id) is \(args.stream.state)")
        switch args.stream.state {
        case .available:
            if let remoteVideoStream = args.stream as? RemoteVideoStream {
                renderRemoteStream(remoteVideoStream)
            }
            break

        case .stopping:
            if let remoteVideoStream = args.stream as? RemoteVideoStream {
                var i = 0
                for data in owner.remoteVideoStreamData {
                    if data.stream.id == remoteVideoStream.id {
                        data.renderer?.dispose()
                        owner.remoteVideoStreamData.remove(at: i)
                    }
                    i += 1
                }
            }
            break

        default:
            break
        }
    }
}

struct PreviewVideoStream: UIViewRepresentable {
    let view:RendererView
    func makeUIView(context: Context) -> UIView {
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct RemoteVideoView: UIViewRepresentable {
    let view:RendererView
    func makeUIView(context: Context) -> UIView {
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appPubs: AppPubs())
    }
}
