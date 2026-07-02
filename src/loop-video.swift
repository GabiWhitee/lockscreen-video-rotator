// Empalma un video consigo mismo (sin re-codificar) hasta alcanzar la
// duración pedida. Se usa para que los videos cortos de Pexels no terminen
// en negro en la pantalla de bloqueo: los aéreos de Apple duran minutos.
// Uso: loop-video <entrada.mov> <salida.mov> <segundos_objetivo>
import AVFoundation
import CoreMedia
import Foundation

@main
struct LoopVideo {
    static func main() async {
        let args = CommandLine.arguments
        guard args.count == 4, let target = Double(args[3]), target > 0 else {
            FileHandle.standardError.write("uso: loop-video <entrada> <salida> <segundos>\n".data(using: .utf8)!)
            exit(64)
        }
        let inURL = URL(fileURLWithPath: args[1])
        let outURL = URL(fileURLWithPath: args[2])
        do {
            let asset = AVURLAsset(url: inURL)
            let duration = try await asset.load(.duration)
            guard duration.seconds > 0 else {
                FileHandle.standardError.write("duracion invalida\n".data(using: .utf8)!)
                exit(1)
            }
            let comp = AVMutableComposition()
            let range = CMTimeRange(start: .zero, duration: duration)
            var t = CMTime.zero
            repeat {
                try await comp.insertTimeRange(range, of: asset, at: t)
                t = CMTimeAdd(t, duration)
            } while t.seconds < target
            try? FileManager.default.removeItem(at: outURL)
            guard let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetPassthrough) else {
                FileHandle.standardError.write("no pude crear la sesion de export\n".data(using: .utf8)!)
                exit(1)
            }
            try await export.export(to: outURL, as: .mov)
            print("ok: \(Int(t.seconds))s")
        } catch {
            FileHandle.standardError.write("error: \(error.localizedDescription)\n".data(using: .utf8)!)
            exit(1)
        }
    }
}
