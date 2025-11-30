import Foundation

struct LayoutFactory {
    static func createGridTemplate(name: String) -> ZoneSet {
        // 1 row, 3 columns (FancyZones default)
        let rows = 1
        let columns = 3
        
        var info = GridLayoutInfo(rows: rows, columns: columns)
        
        // Set percents (sum to 10000)
        // 1 row: 100%
        info.rowsPercents = [10000]
        
        // 3 columns: 33.33%, 33.33%, 33.34%
        // 10000 / 3 = 3333
        info.columnsPercents = [3333, 3333, 3334]
        
        // cellChildMap
        // [0][0] = 0, [0][1] = 1, [0][2] = 2
        info.cellChildMap = [[0, 1, 2]]
        
        return ZoneSet(name: name, gridInfo: info)
    }
    
    static func createCanvasTemplate(name: String) -> ZoneSet {
        // Single centered zone (50% width/height)
        // Canvas coordinates are arbitrary integers, usually relative to work area.
        // Let's assume a reference work area of 1920x1080 for the template.
        let refWidth = 1920
        let refHeight = 1080
        
        let width = refWidth / 2
        let height = refHeight / 2
        let x = (refWidth - width) / 2
        let y = (refHeight - height) / 2
        
        let zone = CanvasZone(x: x, y: y, width: width, height: height, id: 0)
        
        let info = CanvasLayoutInfo(zones: [zone], lastWorkAreaWidth: refWidth, lastWorkAreaHeight: refHeight)
        
        return ZoneSet(name: name, canvasInfo: info)
    }
}
