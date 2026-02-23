import Foundation
import UIKit

/// Splits text into exactly `lines` lines by choosing word-breaks that fit into `maxWidth`.
/// Uses dynamic programming to minimize raggedness while respecting maxWidth.
enum LineBreaker {

    static func split(text: String, lines: Int, font: UIFont, maxWidth: CGFloat) -> [String] {
        let tokens = text.split(separator: " ").map(String.init)
        guard lines > 1, tokens.count > 1 else { return [text] }

        // Precompute token widths (including trailing space except last in line)
        let spaceWidth = " ".size(withAttributes: [.font: font]).width
        let tokenWidths = tokens.map { ($0 as NSString).size(withAttributes: [.font: font]).width }

        // Prefix sums for quick widths
        var prefix: [CGFloat] = Array(repeating: 0, count: tokens.count + 1)
        for i in 0..<tokens.count {
            prefix[i + 1] = prefix[i] + tokenWidths[i]
        }

        func width(i: Int, j: Int) -> CGFloat {
            // tokens[i..<j]
            let words = j - i
            let w = prefix[j] - prefix[i]
            return w + spaceWidth * CGFloat(max(0, words - 1))
        }

        let n = tokens.count
        let L = lines
        let INF = CGFloat.greatestFiniteMagnitude / 4

        // dp[l][i] = min cost to split first i tokens into l lines
        var dp = Array(repeating: Array(repeating: INF, count: n + 1), count: L + 1)
        var prev = Array(repeating: Array(repeating: -1, count: n + 1), count: L + 1)
        dp[0][0] = 0

        for l in 1...L {
            for i in 1...n {
                // try previous cut k
                var best = INF
                var bestK = -1
                // heuristic window to speed up
                let kStart = max(0, i - 40)
                for k in kStart..<i {
                    guard dp[l - 1][k] < INF else { continue }
                    let w = width(i: k, j: i)
                    if w > maxWidth { continue }
                    let leftover = maxWidth - w
                    let penalty: CGFloat = (l == L) ? 0 : (leftover * leftover)
                    let cand = dp[l - 1][k] + penalty
                    if cand < best {
                        best = cand
                        bestK = k
                    }
                }
                dp[l][i] = best
                prev[l][i] = bestK
            }
        }

        // If impossible (too strict maxWidth), fall back to simple greedy wrap (without fixed lines)
        if dp[L][n] >= INF {
            return greedyWrap(tokens: tokens, font: font, maxWidth: maxWidth)
        }

        // backtrack
        var cuts: [(Int, Int)] = []
        var i = n
        var l = L
        while l > 0 {
            let k = prev[l][i]
            if k < 0 { break }
            cuts.append((k, i))
            i = k
            l -= 1
        }
        cuts.reverse()

        var out: [String] = cuts.map { (a, b) in
            tokens[a..<b].joined(separator: " ")
        }

        // Trim empty lines if any
        out = out.filter { !$0.isEmpty }
        return out.isEmpty ? [text] : out
    }

    private static func greedyWrap(tokens: [String], font: UIFont, maxWidth: CGFloat) -> [String] {
        var lines: [String] = []
        var current: [String] = []
        func currentWidth(_ tokens: [String]) -> CGFloat {
            let s = tokens.joined(separator: " ")
            return (s as NSString).size(withAttributes: [.font: font]).width
        }

        for t in tokens {
            if current.isEmpty {
                current = [t]
                continue
            }
            var test = current
            test.append(t)
            if currentWidth(test) <= maxWidth {
                current = test
            } else {
                lines.append(current.joined(separator: " "))
                current = [t]
            }
        }
        if !current.isEmpty { lines.append(current.joined(separator: " ")) }
        return lines
    }
}
